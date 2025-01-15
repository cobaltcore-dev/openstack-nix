[![REUSE status](https://api.reuse.software/badge/github.com/cobaltcore-dev/openstack-nix)](https://api.reuse.software/info/github.com/cobaltcore-dev/openstack-nix)

# openstack-nix

## About this project

A set of Nix packages and NixOS modules allowing the usage of OpenStack in NixOS.

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

## Support, Feedback, Contributing

This project is open to feature requests/suggestions, bug reports etc. via [GitHub issues](https://github.com/cobaltcore-dev/openstack-nix/issues). Contribution and feedback are encouraged and always welcome. For more information about how to contribute, the project structure, as well as additional contribution information, see our [Contribution Guidelines](CONTRIBUTING.md).

## Security / Disclosure
If you find any bug that may be a security problem, please follow our instructions at [in our security policy](https://github.com/cobaltcore-dev/openstack-nix/security/policy) on how to report it. Please do not create GitHub issues for security-related doubts or problems.

## Code of Conduct

We as members, contributors, and leaders pledge to make participation in our community a harassment-free experience for everyone. By participating in this project, you agree to abide by its [Code of Conduct](https://github.com/SAP/.github/blob/main/CODE_OF_CONDUCT.md) at all times.

## Licensing

Copyright 2025 SAP SE or an SAP affiliate company and openstack-nix contributors. Please see our [LICENSE](LICENSE) for copyright and license information. Detailed information including third-party components and their licensing/copyright information is available [via the REUSE tool](https://api.reuse.software/info/github.com/cobaltcore-dev/openstack-nix).
