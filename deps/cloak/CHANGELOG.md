# Change Log

## [Unreleased](https://github.com/danielberkompas/cloak/tree/HEAD)

[Full Changelog](https://github.com/danielberkompas/cloak/compare/v0.4.0...HEAD)

**Closed issues:**

- Migrations in multi tenant applications [\#43](https://github.com/danielberkompas/cloak/issues/43)
- Proposal AES GCM cipher as default Cipher [\#33](https://github.com/danielberkompas/cloak/issues/33)

**Merged pull requests:**

- Add EncryptedTimeField [\#50](https://github.com/danielberkompas/cloak/pull/50) ([danielberkompas](https://github.com/danielberkompas))
- Update the documentation sidebar [\#49](https://github.com/danielberkompas/cloak/pull/49) ([danielberkompas](https://github.com/danielberkompas))
- Add DateTime field, better docs [\#48](https://github.com/danielberkompas/cloak/pull/48) ([danielberkompas](https://github.com/danielberkompas))
- refactor\(Cloak.Config.all/0\): Find ciphers by checking if the module … [\#47](https://github.com/danielberkompas/cloak/pull/47) ([tomciopp](https://github.com/tomciopp))
- feat\(Date Types\): add EncryptedDateField, and EncryptedNaiveDatetimeF… [\#46](https://github.com/danielberkompas/cloak/pull/46) ([tomciopp](https://github.com/tomciopp))

## [v0.4.0](https://github.com/danielberkompas/cloak/tree/v0.4.0) (2018-01-02)
[Full Changelog](https://github.com/danielberkompas/cloak/compare/v0.3.3...v0.4.0)

**Fixed bugs:**

- instructions to cloak plain text fields [\#17](https://github.com/danielberkompas/cloak/issues/17)

**Closed issues:**

- Make json library configurable [\#44](https://github.com/danielberkompas/cloak/issues/44)
- Encryption Arguement Error [\#41](https://github.com/danielberkompas/cloak/issues/41)
- \*\* \(MatchError\) no match of right hand side value: false [\#40](https://github.com/danielberkompas/cloak/issues/40)
- Proposal / Forthcoming PRs: Multiple Ciphers With Keys [\#36](https://github.com/danielberkompas/cloak/issues/36)

**Merged pull requests:**

- Modernize codebase for new release [\#45](https://github.com/danielberkompas/cloak/pull/45) ([danielberkompas](https://github.com/danielberkompas))
- \[\#33\] Add galois counter mode cipher [\#42](https://github.com/danielberkompas/cloak/pull/42) ([tomciopp](https://github.com/tomciopp))
- Fix typespecs / dialyzer errors across the board [\#39](https://github.com/danielberkompas/cloak/pull/39) ([asummers](https://github.com/asummers))
- Allow multiple concurrent ciphers to encrypt [\#37](https://github.com/danielberkompas/cloak/pull/37) ([asummers](https://github.com/asummers))

## [v0.3.3](https://github.com/danielberkompas/cloak/tree/v0.3.3) (2017-09-08)
[Full Changelog](https://github.com/danielberkompas/cloak/compare/v0.3.2...v0.3.3)

**Closed issues:**

- EncryptedIntegerField and EncryptedFloat field do not cast properly [\#35](https://github.com/danielberkompas/cloak/issues/35)

## [v0.3.2](https://github.com/danielberkompas/cloak/tree/v0.3.2) (2017-08-05)
[Full Changelog](https://github.com/danielberkompas/cloak/compare/v0.3.0...v0.3.2)

**Closed issues:**

- Compile warnings [\#34](https://github.com/danielberkompas/cloak/issues/34)
- Allow key to be in Application env [\#31](https://github.com/danielberkompas/cloak/issues/31)
- Add salt option to cloak for increased security [\#26](https://github.com/danielberkompas/cloak/issues/26)
- How to encrypt with user's own key instead of key from config? [\#24](https://github.com/danielberkompas/cloak/issues/24)
- index on encryption\_version [\#23](https://github.com/danielberkompas/cloak/issues/23)
- Adding interoperability with attr\_encrypted? [\#22](https://github.com/danielberkompas/cloak/issues/22)
- Provide Vault Transit cipher [\#21](https://github.com/danielberkompas/cloak/issues/21)

**Merged pull requests:**

- Add ability to pull cipher key from OTP app env [\#32](https://github.com/danielberkompas/cloak/pull/32) ([tielur](https://github.com/tielur))
- Add `prepare\_changes` example to module doc for use with ecto 2.0 [\#27](https://github.com/danielberkompas/cloak/pull/27) ([kgautreaux](https://github.com/kgautreaux))
- clean up compile warnings under Elixir 1.4 [\#25](https://github.com/danielberkompas/cloak/pull/25) ([boydm](https://github.com/boydm))

## [v0.3.0](https://github.com/danielberkompas/cloak/tree/v0.3.0) (2016-09-16)
[Full Changelog](https://github.com/danielberkompas/cloak/compare/v0.2.3...v0.3.0)

**Merged pull requests:**

- Rely on configuration at runtime [\#20](https://github.com/danielberkompas/cloak/pull/20) ([danielberkompas](https://github.com/danielberkompas))

## [v0.2.3](https://github.com/danielberkompas/cloak/tree/v0.2.3) (2016-09-16)
[Full Changelog](https://github.com/danielberkompas/cloak/compare/v0.2.2...v0.2.3)

**Fixed bugs:**

- mix cloak.migrate doesn't update encryption\_version field [\#16](https://github.com/danielberkompas/cloak/issues/16)

**Closed issues:**

- cloak migration not running [\#18](https://github.com/danielberkompas/cloak/issues/18)
- Issue integration with Ecto2? [\#12](https://github.com/danielberkompas/cloak/issues/12)
- Support for Ecto 2.0 [\#10](https://github.com/danielberkompas/cloak/issues/10)
- :system AES keys aren't getting base64 decoded [\#9](https://github.com/danielberkompas/cloak/issues/9)

**Merged pull requests:**

- \[\#16\] Update encryption version in cloak.migrate [\#19](https://github.com/danielberkompas/cloak/pull/19) ([danielberkompas](https://github.com/danielberkompas))
- Fix validation bug in cloak.migrate [\#15](https://github.com/danielberkompas/cloak/pull/15) ([bgeihsgt](https://github.com/bgeihsgt))
- Add key generation example to README. [\#14](https://github.com/danielberkompas/cloak/pull/14) ([rpelyush](https://github.com/rpelyush))
- Add deps badge to README [\#13](https://github.com/danielberkompas/cloak/pull/13) ([rrrene](https://github.com/rrrene))

## [v0.2.2](https://github.com/danielberkompas/cloak/tree/v0.2.2) (2016-05-20)
[Full Changelog](https://github.com/danielberkompas/cloak/compare/v0.2.1...v0.2.2)

**Closed issues:**

- Cloak.EncryptedMapField strange Poison errors [\#6](https://github.com/danielberkompas/cloak/issues/6)
- How to generate keys? [\#5](https://github.com/danielberkompas/cloak/issues/5)

**Merged pull requests:**

- Decode AES environment variable keys from base64 [\#11](https://github.com/danielberkompas/cloak/pull/11) ([philss](https://github.com/philss))
- Update dependencies [\#7](https://github.com/danielberkompas/cloak/pull/7) ([danielberkompas](https://github.com/danielberkompas))

## [v0.2.1](https://github.com/danielberkompas/cloak/tree/v0.2.1) (2016-04-06)
[Full Changelog](https://github.com/danielberkompas/cloak/compare/v0.2.0...v0.2.1)

**Merged pull requests:**

- Update examples to reflect the remotion of Cloak.Model [\#4](https://github.com/danielberkompas/cloak/pull/4) ([philss](https://github.com/philss))

## [v0.2.0](https://github.com/danielberkompas/cloak/tree/v0.2.0) (2015-12-16)
[Full Changelog](https://github.com/danielberkompas/cloak/compare/v0.1.0...v0.2.0)

**Merged pull requests:**

- Added sample migration to README [\#3](https://github.com/danielberkompas/cloak/pull/3) ([mspanc](https://github.com/mspanc))
- Added ability to store keys in the environment variables [\#2](https://github.com/danielberkompas/cloak/pull/2) ([mspanc](https://github.com/mspanc))
- Inform that key must be 16, 24 or 32 bytes long [\#1](https://github.com/danielberkompas/cloak/pull/1) ([mspanc](https://github.com/mspanc))

## [v0.1.0](https://github.com/danielberkompas/cloak/tree/v0.1.0) (2015-09-22)
[Full Changelog](https://github.com/danielberkompas/cloak/compare/v0.1.0-pre...v0.1.0)

## [v0.1.0-pre](https://github.com/danielberkompas/cloak/tree/v0.1.0-pre) (2015-09-16)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*