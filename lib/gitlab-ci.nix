{ input }:
let
  # This helper builds a path string from a current nesting position by joining
  # the current path segment and the attribute using ".". Basically a join
  # operation to deal with the root set.
  pathString = builtins.foldl' (
    current: attr: (if current == "" then "" else current + ".") + attr
  ) "";

  isDerivation = x: x ? "type" && x.type == "derivation";

  # Recursively descend into all reachable build attributes
  #   currentPath : current position in the nesting structure
  #   currentSet  : current attribute set
  # For all attributes in the current set:
  #   - If the attribute is a derivation, add it to the list of build attributes
  #   - If the attribute is a nested set, recursively descend into it, extending
  #     the current path by ".<attribute name>"
  discoverBuildAttributes =
    currentPath: currentSet:
    let
      accumulate =
        accumList: name:
        let
          value = currentSet."${name}";
          attrsInSet =
            if isDerivation value then
              [
                {
                  path = (pathString (currentPath ++ [ name ]));
                  drv = value;
                }
              ]
            else if builtins.typeOf value == "set" then
              discoverBuildAttributes (currentPath ++ [ name ]) value
            else
              [ ];
        in
        accumList ++ attrsInSet;
    in
    builtins.foldl' accumulate [ ] (builtins.attrNames currentSet);

  releaseNixAttributes = discoverBuildAttributes [ ] input;

  # The common build job will need to be tagged as "nix" and runs the
  # command "nix build .#<build attribute>".
  defaultBuildJob = attrPath: {
    "tags" = [ "native-nix" ];
    "stage" = "build";
    "script" = [
      "NIX_PATH= nix build .#${attrPath}"
    ];
  };

  nixIntegrationTestBuildJob = attrPath: {
    "tags" = [ "native-nix" ];
    "stage" = "test";
    "script" = [
      "NIX_PATH= nix build .#${attrPath}"
    ];
  };

  hasMetaTag =
    drv: tag: builtins.hasAttr "meta" drv && builtins.hasAttr "tag" (drv.meta) && drv.meta.tag == tag;

  generateJobDescs =
    attr:
    let
      drv = attr.drv;
      attrPath = attr.path;
    in
    if hasMetaTag drv "nix-integration-test" then
      [
        {
          name = "${attrPath}";
          value = nixIntegrationTestBuildJob attrPath;
        }
      ]
    else
      [
        {
          name = "${attrPath}";
          value = defaultBuildJob attrPath;
        }
      ];

  # Build the job list: Each job is represented as one element with name
  # denoting the build job's name and value being the job's attributes.
  # This will later be converted to an attribute set using listToAttrs.
  jobs = builtins.concatMap generateJobDescs releaseNixAttributes;

  # Global settings of the pipeline (e.g., default image, default before_script)
  header = {
    # define workflow rules so the child pipeline is created in all possible pipeline contexts,
    # e.g., in a MR pipeline
    workflow = {
      rules = [
        { when = "always"; }
      ];
    };
    # Nix builds need to be able to access our Gitlab to fetch repositories.
    before_script = [
      "git config --global --add url.\${CI_SERVER_PROTOCOL}://gitlab-ci-token:\${CI_JOB_TOKEN}@\${CI_SERVER_HOST}/.insteadOf \"git@\${CI_SERVER_HOST}:\""
      "git config --global --add url.$\{CI_SERVER_PROTOCOL}://gitlab-ci-token:\${CI_JOB_TOKEN}@\${CI_SERVER_HOST}/.insteadOf \"ssh://git@\${CI_SERVER_HOST}/\""
    ];
  };
in
builtins.toFile "generated_ci.yaml" (builtins.toJSON (header // (builtins.listToAttrs jobs)))
