{
  fetchPypi,
  keystoneauth1,
  lib,
  openstacksdk,
  oslo-i18n,
  oslo-utils,
  python3Packages,
  writeText,
}:
let
  inherit (python3Packages)
    ddt
    pbr
    prettytable
    pyopenssl
    requests
    requests-mock
    stestr
    testscenarios
    warlock
    wrapt
    ;

  disabledTests = [
    # Skip tests which require networking.
    "test_http_chunked_response"
    "test_v1_download_has_no_stray_output_to_stdout"
    "test_v2_requests_valid_cert_verification"
    "test_download_has_no_stray_output_to_stdout"
    "test_v1_requests_cert_verification_no_compression"
    "test_v1_requests_cert_verification"
    "test_v2_download_has_no_stray_output_to_stdout"
    "test_v2_requests_bad_ca"
    "test_v2_requests_bad_cert"
    "test_v2_requests_cert_verification_no_compression"
    "test_v2_requests_cert_verification"
    "test_v2_requests_valid_cert_no_key"
    "test_v2_requests_valid_cert_verification_no_compression"
    "test_log_request_id_once"
    # asserts exact amount of mock calls
    "test_cache_schemas_gets_when_forced"
    "test_cache_schemas_gets_when_not_exists"
    # binary dosn't exist in nixos: /bin/echo
    "test_image_update_data_is_read_from_pipe"
  ];
in
python3Packages.buildPythonPackage rec {
  pname = "python-glanceclient";
  version = "4.7.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-wZRS7xLaPEhLadIqiIznp0kQvbh4O76RJIxg76U3iBA=";
  };

  pyproject = true;
  build-system = [
    python3Packages.pbr
    python3Packages.setuptools
  ];

  propagatedBuildInputs = [
    keystoneauth1
    oslo-i18n
    oslo-utils
    pbr
    prettytable
    pyopenssl
    requests
    warlock
    wrapt
  ];

  nativeCheckInputs = [
    ddt
    openstacksdk
    requests-mock
    stestr
    testscenarios
  ];

  checkInputs = [
    ddt
    keystoneauth1
    oslo-i18n
    oslo-utils
    pbr
    prettytable
    pyopenssl
    requests
    requests-mock
    testscenarios
    warlock
    wrapt
  ];

  checkPhase = ''
    runHook preCheck
    stestr run -e ${writeText "disabled-tests" (lib.concatStringsSep "\n" disabledTests)}
    runHook postCheck
  '';

}
