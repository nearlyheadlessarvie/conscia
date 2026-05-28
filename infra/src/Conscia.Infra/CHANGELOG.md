# Changelog

## [1.5.1](https://github.com/nearlyheadlessarvie/conscia/compare/infra/v1.5.0...infra/v1.5.1) (2026-05-28)


### Bug Fixes

* **infra:** align managed login branding schema ([#130](https://github.com/nearlyheadlessarvie/conscia/issues/130)) ([87048aa](https://github.com/nearlyheadlessarvie/conscia/commit/87048aa1189163943a11ce48ceb073c49970114a))

## [1.5.0](https://github.com/nearlyheadlessarvie/conscia/compare/infra/v1.4.0...infra/v1.5.0) (2026-05-28)


### Features

* **infra:** add cognito pre-signup account linker ([#125](https://github.com/nearlyheadlessarvie/conscia/issues/125)) ([174f0d0](https://github.com/nearlyheadlessarvie/conscia/commit/174f0d089b38ced4d0bf31571176b3e6c831bea8))

## [1.4.0](https://github.com/nearlyheadlessarvie/conscia/compare/infra/v1.3.0...infra/v1.4.0) (2026-05-28)


### Features

* **app:** cut over mobile auth to cognito managed login ([#118](https://github.com/nearlyheadlessarvie/conscia/issues/118)) ([1823f77](https://github.com/nearlyheadlessarvie/conscia/commit/1823f779bcc460cf5e5b513c060e347e9e26b3d8))

## [1.3.0](https://github.com/nearlyheadlessarvie/conscia/compare/infra/v1.2.6...infra/v1.3.0) (2026-05-28)


### Features

* **infra:** add cognito managed login foundation ([#116](https://github.com/nearlyheadlessarvie/conscia/issues/116)) ([765ac9a](https://github.com/nearlyheadlessarvie/conscia/commit/765ac9ad7ebf4570671f82fdf1d194c149c7feb3))

## [1.2.6](https://github.com/nearlyheadlessarvie/conscia/compare/infra/v1.2.5...infra/v1.2.6) (2026-05-27)


### Bug Fixes

* clarify Cognito passkey availability ([#108](https://github.com/nearlyheadlessarvie/conscia/issues/108)) ([a5f5aaa](https://github.com/nearlyheadlessarvie/conscia/commit/a5f5aaa896f916c0e954c99b82d2f38fc0f7a6e2))

## [1.2.5](https://github.com/nearlyheadlessarvie/conscia/compare/infra/v1.2.4...infra/v1.2.5) (2026-05-27)


### Bug Fixes

* **api:** source version metadata from release artifact ([#99](https://github.com/nearlyheadlessarvie/conscia/issues/99)) ([77346e6](https://github.com/nearlyheadlessarvie/conscia/commit/77346e6b3155b467a9b6a5a748a8fc81e20b68ff))

## [1.2.4](https://github.com/nearlyheadlessarvie/conscia/compare/infra/v1.2.3...infra/v1.2.4) (2026-05-27)


### Bug Fixes

* **api:** add deploy metadata and auth diagnostics ([#93](https://github.com/nearlyheadlessarvie/conscia/issues/93)) ([6bc3f21](https://github.com/nearlyheadlessarvie/conscia/commit/6bc3f21f15cd3fb8c0d943609a4db23fc5f781b4))

## [1.2.3](https://github.com/nearlyheadlessarvie/conscia/compare/infra/v1.2.2...infra/v1.2.3) (2026-05-27)


### Bug Fixes

* **infra:** ignore incomplete icloud cname records ([#87](https://github.com/nearlyheadlessarvie/conscia/issues/87)) ([490d74d](https://github.com/nearlyheadlessarvie/conscia/commit/490d74d67491352dc05e7ca1d00ec6c1c862f92b))

## [1.2.2](https://github.com/nearlyheadlessarvie/conscia/compare/infra/v1.2.1...infra/v1.2.2) (2026-05-27)


### Bug Fixes

* **infra:** send cognito emails from ses domain ([36a8cbc](https://github.com/nearlyheadlessarvie/conscia/commit/36a8cbcac63e95423dc41bc1d9681381c7c5e8f2))

## [1.2.1](https://github.com/nearlyheadlessarvie/conscia/compare/infra/v1.2.0...infra/v1.2.1) (2026-05-26)


### Bug Fixes

* **infra:** rewrite static page routes at cloudfront ([6b2ef2e](https://github.com/nearlyheadlessarvie/conscia/commit/6b2ef2e656a2d672d7e87fc703e567ba947aca56))

## [1.2.0](https://github.com/nearlyheadlessarvie/conscia/compare/infra/v1.1.1...infra/v1.2.0) (2026-05-26)


### Features

* harden production runtime and add passkeys ([5e77481](https://github.com/nearlyheadlessarvie/conscia/commit/5e77481fec95f2976da49e157829c726c587cee8))
* harden production runtime and add passkeys ([d8bf1b6](https://github.com/nearlyheadlessarvie/conscia/commit/d8bf1b60438a24e0b8e496e58cc50202b59d55f5))


### Bug Fixes

* **infra:** accept icloud dns json and correct cdk diff ([95aa33d](https://github.com/nearlyheadlessarvie/conscia/commit/95aa33da105409193d89c45a6c91e9af96dbdf9b))
* **infra:** allow synth without published assets ([025ef63](https://github.com/nearlyheadlessarvie/conscia/commit/025ef639fc4e977847187180ee5845e6e330bea0))
* **infra:** avoid lambda log group ownership conflicts ([a204770](https://github.com/nearlyheadlessarvie/conscia/commit/a20477001a595b6914b071344ac7245debe09a5c))
* **infra:** grant deploy role secrets manager access ([dc93abb](https://github.com/nearlyheadlessarvie/conscia/commit/dc93abb2087c6824dbc2876de58dc2d52eda6c96))
* **infra:** group route53 txt records by hostname ([aae99f2](https://github.com/nearlyheadlessarvie/conscia/commit/aae99f2a0e058c7c95b72f67bc85b808dd80cdb7))
* **infra:** move lambda runtime secrets to secrets manager ([601025b](https://github.com/nearlyheadlessarvie/conscia/commit/601025be79b1daf56d81b9acb83f91ae36dea605))
* productionize recurring and receipt scanning ([836268c](https://github.com/nearlyheadlessarvie/conscia/commit/836268c2fa239d7d293222f27158e8adf5e6dc18))

## [1.1.1](https://github.com/nearlyheadlessarvie/conscia/compare/infra/v1.1.0...infra/v1.1.1) (2026-05-26)


### Bug Fixes

* **infra:** accept icloud dns json and correct cdk diff ([95aa33d](https://github.com/nearlyheadlessarvie/conscia/commit/95aa33da105409193d89c45a6c91e9af96dbdf9b))
* **infra:** group route53 txt records by hostname ([aae99f2](https://github.com/nearlyheadlessarvie/conscia/commit/aae99f2a0e058c7c95b72f67bc85b808dd80cdb7))
* **infra:** move lambda runtime secrets to secrets manager ([601025b](https://github.com/nearlyheadlessarvie/conscia/commit/601025be79b1daf56d81b9acb83f91ae36dea605))

## [1.1.0](https://github.com/nearlyheadlessarvie/conscia/compare/infra/v1.0.0...infra/v1.1.0) (2026-05-26)


### Features

* harden production runtime and add passkeys ([5e77481](https://github.com/nearlyheadlessarvie/conscia/commit/5e77481fec95f2976da49e157829c726c587cee8))
* harden production runtime and add passkeys ([d8bf1b6](https://github.com/nearlyheadlessarvie/conscia/commit/d8bf1b60438a24e0b8e496e58cc50202b59d55f5))


### Bug Fixes

* **infra:** allow synth without published assets ([025ef63](https://github.com/nearlyheadlessarvie/conscia/commit/025ef639fc4e977847187180ee5845e6e330bea0))
* productionize recurring and receipt scanning ([836268c](https://github.com/nearlyheadlessarvie/conscia/commit/836268c2fa239d7d293222f27158e8adf5e6dc18))
