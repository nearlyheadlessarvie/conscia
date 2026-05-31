# Changelog

## [1.4.3](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.4.2...api/v1.4.3) (2026-05-31)


### Bug Fixes

* harden passkey device removal and social linker ([#186](https://github.com/nearlyheadlessarvie/conscia/issues/186)) ([9383d16](https://github.com/nearlyheadlessarvie/conscia/commit/9383d16d1e63514df320768b799e5609dcb78716))

## [1.4.2](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.4.1...api/v1.4.2) (2026-05-31)


### Bug Fixes

* handle Cognito passkey setup diagnostics ([#183](https://github.com/nearlyheadlessarvie/conscia/issues/183)) ([3c625a3](https://github.com/nearlyheadlessarvie/conscia/commit/3c625a30432db89609d3602b0dccf77193841fe1))

## [1.4.1](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.4.0...api/v1.4.1) (2026-05-31)


### Bug Fixes

* remediate whole-project audit findings ([b9806f5](https://github.com/nearlyheadlessarvie/conscia/commit/b9806f510ec04ebe658cb573c25f798ad2cec23f))

## [1.4.0](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.3.5...api/v1.4.0) (2026-05-31)


### Features

* manage Cognito passkeys ([#170](https://github.com/nearlyheadlessarvie/conscia/issues/170)) ([83c1505](https://github.com/nearlyheadlessarvie/conscia/commit/83c1505d1d2ee41a65d347a8cdfcb30cdde71568))

## [1.3.5](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.3.4...api/v1.3.5) (2026-05-30)


### Bug Fixes

* harden Cognito auth bootstrap and password flows ([#165](https://github.com/nearlyheadlessarvie/conscia/issues/165)) ([30b301c](https://github.com/nearlyheadlessarvie/conscia/commit/30b301ccd3c418ebc854460bbdad5caeb31c10ab))

## [1.3.4](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.3.3...api/v1.3.4) (2026-05-30)


### Bug Fixes

* complete passkey registration and reviewer provisioning ([#162](https://github.com/nearlyheadlessarvie/conscia/issues/162)) ([c91e85c](https://github.com/nearlyheadlessarvie/conscia/commit/c91e85ce01b8cd922626d7fb603da81d3b2fa67a))

## [1.3.3](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.3.2...api/v1.3.3) (2026-05-29)


### Bug Fixes

* harden family invites, auth, and API observability ([#158](https://github.com/nearlyheadlessarvie/conscia/issues/158)) ([d56f3c2](https://github.com/nearlyheadlessarvie/conscia/commit/d56f3c2fbc6595277209e47b4d4bb7fcaa7cc2fb))

## [1.3.2](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.3.1...api/v1.3.2) (2026-05-29)


### Bug Fixes

* harden auth bootstrap, receipts, passkeys, recurrence, and infra ([#152](https://github.com/nearlyheadlessarvie/conscia/issues/152)) ([1e47a91](https://github.com/nearlyheadlessarvie/conscia/commit/1e47a91871ea0c804378b78b338de895d7f977e4))

## [1.3.1](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.3.0...api/v1.3.1) (2026-05-29)


### Bug Fixes

* **api:** parse cognito identities object claims ([#147](https://github.com/nearlyheadlessarvie/conscia/issues/147)) ([9e63ed2](https://github.com/nearlyheadlessarvie/conscia/commit/9e63ed2a4357b4f2ca2a591086e6643521cf0692))

## [1.3.0](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.2.0...api/v1.3.0) (2026-05-29)


### Features

* **app:** add passkey-first sign-in preference ([aedec11](https://github.com/nearlyheadlessarvie/conscia/commit/aedec11266c5462ace9b190d997ab6171edecfec))
* **app:** restore hybrid in-app auth code flow ([aedec11](https://github.com/nearlyheadlessarvie/conscia/commit/aedec11266c5462ace9b190d997ab6171edecfec))
* **infra:** wire admin bootstrap emails release configuration ([aedec11](https://github.com/nearlyheadlessarvie/conscia/commit/aedec11266c5462ace9b190d997ab6171edecfec))


### Bug Fixes

* **api:** delete Cognito user during account deletion ([aedec11](https://github.com/nearlyheadlessarvie/conscia/commit/aedec11266c5462ace9b190d997ab6171edecfec))
* **app:** keep Cognito social auth cancellation and signout local ([aedec11](https://github.com/nearlyheadlessarvie/conscia/commit/aedec11266c5462ace9b190d997ab6171edecfec))
* **infra:** preserve Cognito pre-signup trigger event version ([aedec11](https://github.com/nearlyheadlessarvie/conscia/commit/aedec11266c5462ace9b190d997ab6171edecfec))

## [1.2.0](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.1.6...api/v1.2.0) (2026-05-28)


### Features

* **app:** cut over mobile auth to cognito managed login ([#118](https://github.com/nearlyheadlessarvie/conscia/issues/118)) ([1823f77](https://github.com/nearlyheadlessarvie/conscia/commit/1823f779bcc460cf5e5b513c060e347e9e26b3d8))

## [1.1.6](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.1.5...api/v1.1.6) (2026-05-27)


### Bug Fixes

* clarify Cognito passkey availability ([#108](https://github.com/nearlyheadlessarvie/conscia/issues/108)) ([a5f5aaa](https://github.com/nearlyheadlessarvie/conscia/commit/a5f5aaa896f916c0e954c99b82d2f38fc0f7a6e2))

## [1.1.5](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.1.4...api/v1.1.5) (2026-05-27)


### Bug Fixes

* **api:** configure cognito token issuer ([#100](https://github.com/nearlyheadlessarvie/conscia/issues/100)) ([4381e38](https://github.com/nearlyheadlessarvie/conscia/commit/4381e384f67eb7ac18098e4521d617326aafbe44))
* **api:** source version metadata from release artifact ([#99](https://github.com/nearlyheadlessarvie/conscia/issues/99)) ([77346e6](https://github.com/nearlyheadlessarvie/conscia/commit/77346e6b3155b467a9b6a5a748a8fc81e20b68ff))

## [1.1.4](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.1.3...api/v1.1.4) (2026-05-27)


### Bug Fixes

* **api:** add deploy metadata and auth diagnostics ([#93](https://github.com/nearlyheadlessarvie/conscia/issues/93)) ([6bc3f21](https://github.com/nearlyheadlessarvie/conscia/commit/6bc3f21f15cd3fb8c0d943609a4db23fc5f781b4))

## [1.1.3](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.1.2...api/v1.1.3) (2026-05-27)


### Bug Fixes

* **api:** correlate app errors with backend failures ([34066bb](https://github.com/nearlyheadlessarvie/conscia/commit/34066bb7124da8296e12b1504a44bdf450463e1e))
* **api:** correlate app errors with backend failures ([6125e77](https://github.com/nearlyheadlessarvie/conscia/commit/6125e77095ac7f05371b9a4b25c87ed3065827a8))
* **api:** resolve cognito region from lambda env ([4ffdcfe](https://github.com/nearlyheadlessarvie/conscia/commit/4ffdcfe985c7bcaf199e22f9778d9e99a1532093))

## [1.1.2](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.1.1...api/v1.1.2) (2026-05-26)


### Bug Fixes

* **api:** remove public health readiness endpoints ([26b57bf](https://github.com/nearlyheadlessarvie/conscia/commit/26b57bf8a366c63b9af7b27ae8cce643338a403f))
* **api:** remove public health readiness endpoints ([fe5fb51](https://github.com/nearlyheadlessarvie/conscia/commit/fe5fb513f7574cb2e2f7b64123c83bc5ea0ec8be))

## [1.1.1](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.1.0...api/v1.1.1) (2026-05-26)


### Bug Fixes

* **api:** wire lambda hosting and correct smoke test ([4b273ca](https://github.com/nearlyheadlessarvie/conscia/commit/4b273cad15195ebbc886410f4b8c16984708127f))

## [1.1.0](https://github.com/nearlyheadlessarvie/conscia/compare/api/v1.0.0...api/v1.1.0) (2026-05-26)


### Features

* add query versioning and release automation ([4bf0eb5](https://github.com/nearlyheadlessarvie/conscia/commit/4bf0eb5e71de8f77d7a38bbe5c37631aa661e0ad))
* **api:** add admin entitlement operations ([94785a4](https://github.com/nearlyheadlessarvie/conscia/commit/94785a4108cff457d5b3b75a9e573b2012c02ca1))
* **api:** add lifetime entitlement status merge ([852501f](https://github.com/nearlyheadlessarvie/conscia/commit/852501f6e15823ce8ba8d2994896416f3fa20603))
* **api:** add transaction date range filtering ([ff00372](https://github.com/nearlyheadlessarvie/conscia/commit/ff0037247812aa5d8d88df1b6850717251ea6e7f))
* **api:** handle Apple subscription notifications ([0ea883f](https://github.com/nearlyheadlessarvie/conscia/commit/0ea883f4e90c70a957042110da9a514617558833))
* harden production runtime and add passkeys ([5e77481](https://github.com/nearlyheadlessarvie/conscia/commit/5e77481fec95f2976da49e157829c726c587cee8))
* harden production runtime and add passkeys ([d8bf1b6](https://github.com/nearlyheadlessarvie/conscia/commit/d8bf1b60438a24e0b8e496e58cc50202b59d55f5))


### Bug Fixes

* **api:** add admin access probe ([e23f84d](https://github.com/nearlyheadlessarvie/conscia/commit/e23f84dbaedb7c81fba3ea40a5dd8c0ac4c0e2fa))
* **api:** register cognito client in development ([9e046da](https://github.com/nearlyheadlessarvie/conscia/commit/9e046da47caa722167e529fa8aac3d016e220982))
* **infra:** move lambda runtime secrets to secrets manager ([601025b](https://github.com/nearlyheadlessarvie/conscia/commit/601025be79b1daf56d81b9acb83f91ae36dea605))
* make smart nearby suggestions device-local ([a613e37](https://github.com/nearlyheadlessarvie/conscia/commit/a613e377b8d1dec9d70ad8ce4958ad0caf67bf74))
* make smart nearby suggestions device-local ([0827c02](https://github.com/nearlyheadlessarvie/conscia/commit/0827c024aa5d5ce925557532b0f6fc1e1f59b5f8))
* productionize recurring and receipt scanning ([836268c](https://github.com/nearlyheadlessarvie/conscia/commit/836268c2fa239d7d293222f27158e8adf5e6dc18))
