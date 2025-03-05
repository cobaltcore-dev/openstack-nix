[![REUSE status](https://api.reuse.software/badge/github.com/cobaltcore-dev/openstack-nix)](https://api.reuse.software/info/github.com/cobaltcore-dev/openstack-nix)

# openstack-nix

A set of Nix packages and NixOS modules allowing the usage of OpenStack in NixOS.

## About this project

The repository contains the following things:

* Nix package descriptions for OpenStack libraries and executables
* NixOS modules starting the basic OpenStack services (Keystone, Glance, Placement, Neutron, Nova, ...)
* NixOS modules mimicking the configuration for a [minimal OpenStack setup](https://docs.openstack.org/install-guide/openstack-services.html#minimal-deployment-for-2024-2-dalmatian) (e.g. create users and databases)
* NixOS tests checking basic OpenStack functions (e.g. server creation and live migration)

## Style Checks

In our repo, we use [pre-commit](https://pre-commit.com/) via
[pre-commit-hooks.nix](https://github.com/cachix/pre-commit-hooks.nix)
to enforce a consistent style.

If you use the `nix develop` environment, pre-commit will be
automatically configured for you and fix or flag any style issues when you
commit.

When style changes are necessary on files that were not touched in the
commit, you can re-run the checks on all files using:

```console
$ pre-commit run --all-files
```

This happens for example when the version of the style checking tool
is updated or its configuration was changed.

Single checks can be skipped using the
[`SKIP`](https://pre-commit.com/#temporarily-disabling-hooks)
environment variable, if they are problematic. As an escape hatch, use
`git commit --no-verify` to avoid running _any_ checks.

## Usage

The `openstack-nix` repository exports everything via a nix flake. You can
specify it as a flake input in your project or directly build certain
attributes.

### OpenStack Nix packages

The OpenStack services require a number of dependencies that are exported via:

```nix
openstack-nix.packages
```

### NixOS modules

The NixOS modules are exported via

```nix
openstack-nix.nixosModules
```

There are modules to setup the OpenStack controller, an OpenStack compute node
and modules simplifying the creation of new NixOS tests.

### NixOS tests

The NixOS tests are located under the `tests` attribute. To execute a NixOS test
do the following:

```shell
nix build .#tests.x86_64-linux.<test-name>
```

If you want an interactive session:

```shell
nix build .#tests.x86_64-linux.<test-name>.driverInteractive
./result/bin/nixos-test-driver
```

## Scope

OpenStack is a very large and super actively maintained project. We are aware that we cannot keep track of all its development or offer every single configuration option via NixOS modules.

Therefore, we restricted ourself to the following goals for this project:

* Make it easy to use OpenStack in a sane and useful default configuration.
* Allow the user to customize packages and configurations, but there are no
  guarantees that things will work then.

## Support, Feedback, Contributing

This project is open to feature requests/suggestions, bug reports etc. via [GitHub issues](https://github.com/cobaltcore-dev/openstack-nix/issues). Contribution and feedback are encouraged and always welcome. For more information about how to contribute, the project structure, as well as additional contribution information, see our [Contribution Guidelines](CONTRIBUTING.md).

## Security / Disclosure
If you find any bug that may be a security problem, please follow our instructions at [in our security policy](https://github.com/cobaltcore-dev/openstack-nix/security/policy) on how to report it. Please do not create GitHub issues for security-related doubts or problems.

## Code of Conduct

We as members, contributors, and leaders pledge to make participation in our community a harassment-free experience for everyone. By participating in this project, you agree to abide by its [Code of Conduct](https://github.com/SAP/.github/blob/main/CODE_OF_CONDUCT.md) at all times.

## Licensing

Copyright 2025 SAP SE or an SAP affiliate company and openstack-nix contributors. Please see our [LICENSE](LICENSE) for copyright and license information. Detailed information including third-party components and their licensing/copyright information is available [via the REUSE tool](https://api.reuse.software/info/github.com/cobaltcore-dev/openstack-nix).
