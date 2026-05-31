# Changelog

## [2.2.1](https://github.com/nearlyheadlessarvie/conscia/compare/app/v2.2.0...app/v2.2.1) (2026-05-31)


### Bug Fixes

* remediate whole-project audit findings ([b9806f5](https://github.com/nearlyheadlessarvie/conscia/commit/b9806f510ec04ebe658cb573c25f798ad2cec23f))

## [2.2.0](https://github.com/nearlyheadlessarvie/conscia/compare/app/v2.1.3...app/v2.2.0) (2026-05-31)


### Features

* manage Cognito passkeys ([#170](https://github.com/nearlyheadlessarvie/conscia/issues/170)) ([83c1505](https://github.com/nearlyheadlessarvie/conscia/commit/83c1505d1d2ee41a65d347a8cdfcb30cdde71568))

## [2.1.3](https://github.com/nearlyheadlessarvie/conscia/compare/app/v2.1.2...app/v2.1.3) (2026-05-30)


### Bug Fixes

* harden Cognito auth bootstrap and password flows ([#165](https://github.com/nearlyheadlessarvie/conscia/issues/165)) ([30b301c](https://github.com/nearlyheadlessarvie/conscia/commit/30b301ccd3c418ebc854460bbdad5caeb31c10ab))

## [2.1.2](https://github.com/nearlyheadlessarvie/conscia/compare/app/v2.1.1...app/v2.1.2) (2026-05-29)


### Bug Fixes

* harden family invites, auth, and API observability ([#158](https://github.com/nearlyheadlessarvie/conscia/issues/158)) ([d56f3c2](https://github.com/nearlyheadlessarvie/conscia/commit/d56f3c2fbc6595277209e47b4d4bb7fcaa7cc2fb))

## [2.1.1](https://github.com/nearlyheadlessarvie/conscia/compare/app/v2.1.0...app/v2.1.1) (2026-05-29)


### Bug Fixes

* harden auth bootstrap, receipts, passkeys, recurrence, and infra ([#152](https://github.com/nearlyheadlessarvie/conscia/issues/152)) ([1e47a91](https://github.com/nearlyheadlessarvie/conscia/commit/1e47a91871ea0c804378b78b338de895d7f977e4))

## [2.1.0](https://github.com/nearlyheadlessarvie/conscia/compare/app/v2.0.1...app/v2.1.0) (2026-05-29)


### Features

* **app:** add passkey-first sign-in preference ([aedec11](https://github.com/nearlyheadlessarvie/conscia/commit/aedec11266c5462ace9b190d997ab6171edecfec))
* **app:** restore hybrid in-app auth code flow ([aedec11](https://github.com/nearlyheadlessarvie/conscia/commit/aedec11266c5462ace9b190d997ab6171edecfec))
* **infra:** wire admin bootstrap emails release configuration ([aedec11](https://github.com/nearlyheadlessarvie/conscia/commit/aedec11266c5462ace9b190d997ab6171edecfec))


### Bug Fixes

* **api:** delete Cognito user during account deletion ([aedec11](https://github.com/nearlyheadlessarvie/conscia/commit/aedec11266c5462ace9b190d997ab6171edecfec))
* **app:** clear stale onboarding state on sign in ([#148](https://github.com/nearlyheadlessarvie/conscia/issues/148)) ([d3b9d77](https://github.com/nearlyheadlessarvie/conscia/commit/d3b9d77b1c4264bd3d0755f6ad9aa28720e66411))
* **app:** keep Cognito social auth cancellation and signout local ([aedec11](https://github.com/nearlyheadlessarvie/conscia/commit/aedec11266c5462ace9b190d997ab6171edecfec))
* **infra:** preserve Cognito pre-signup trigger event version ([aedec11](https://github.com/nearlyheadlessarvie/conscia/commit/aedec11266c5462ace9b190d997ab6171edecfec))

## [2.0.1](https://github.com/nearlyheadlessarvie/conscia/compare/app/v2.0.0...app/v2.0.1) (2026-05-28)


### Bug Fixes

* **app:** remove auth subdomain managed login surface ([#132](https://github.com/nearlyheadlessarvie/conscia/issues/132)) ([059f268](https://github.com/nearlyheadlessarvie/conscia/commit/059f26810f0c898ad764528a6c480b919e267059))

## [2.0.0](https://github.com/nearlyheadlessarvie/conscia/compare/app/v1.2.0...app/v2.0.0) (2026-05-28)


### ⚠ BREAKING CHANGES

* **app:** the app now requires iOS 17.4+ and macOS 14.4+ to use the upstream managed login auth plugin.

### Bug Fixes

* **app:** accept custom auth callback scheme ([#124](https://github.com/nearlyheadlessarvie/conscia/issues/124)) ([6019b57](https://github.com/nearlyheadlessarvie/conscia/commit/6019b570dcf3c691e6bd8994dfd0a7d991146b1c))
* **app:** raise apple minimums for managed login ([#129](https://github.com/nearlyheadlessarvie/conscia/issues/129)) ([dd3f4c7](https://github.com/nearlyheadlessarvie/conscia/commit/dd3f4c7282f2f50bdf678d93ababc5fd371034d9))

## [1.2.0](https://github.com/nearlyheadlessarvie/conscia/compare/app/v1.1.7...app/v1.2.0) (2026-05-28)


### Features

* **app:** cut over mobile auth to cognito managed login ([#118](https://github.com/nearlyheadlessarvie/conscia/issues/118)) ([1823f77](https://github.com/nearlyheadlessarvie/conscia/commit/1823f779bcc460cf5e5b513c060e347e9e26b3d8))

## [1.1.7](https://github.com/nearlyheadlessarvie/conscia/compare/app/v1.1.6...app/v1.1.7) (2026-05-27)


### Bug Fixes

* **app:** resolve mobile subscription and auth regressions ([#114](https://github.com/nearlyheadlessarvie/conscia/issues/114)) ([5ddd9ff](https://github.com/nearlyheadlessarvie/conscia/commit/5ddd9ff13e20948d2c1d71cfafca13d3c97f4af4))

## [1.1.6](https://github.com/nearlyheadlessarvie/conscia/compare/app/v1.1.5...app/v1.1.6) (2026-05-27)


### Bug Fixes

* **app:** pin connectivity_plus for ios builds ([#97](https://github.com/nearlyheadlessarvie/conscia/issues/97)) ([2ed71ff](https://github.com/nearlyheadlessarvie/conscia/commit/2ed71fffc112c18419ae10b4bc57313242ae03aa))
* **app:** surface google sign-in failures ([#102](https://github.com/nearlyheadlessarvie/conscia/issues/102)) ([133684a](https://github.com/nearlyheadlessarvie/conscia/commit/133684a3ec06cdc31fc9e294880fdd39bab43f11))

## [1.1.5](https://github.com/nearlyheadlessarvie/conscia/compare/app/v1.1.4...app/v1.1.5) (2026-05-27)


### Bug Fixes

* **app:** pin runner release signing profile ([#91](https://github.com/nearlyheadlessarvie/conscia/issues/91)) ([a605322](https://github.com/nearlyheadlessarvie/conscia/commit/a605322920d8d8fc56a34e5b43ae4e1b3cb36ba6))

## [1.1.4](https://github.com/nearlyheadlessarvie/conscia/compare/app/v1.1.3...app/v1.1.4) (2026-05-27)


### Bug Fixes

* **api:** correlate app errors with backend failures ([34066bb](https://github.com/nearlyheadlessarvie/conscia/commit/34066bb7124da8296e12b1504a44bdf450463e1e))
* **api:** correlate app errors with backend failures ([6125e77](https://github.com/nearlyheadlessarvie/conscia/commit/6125e77095ac7f05371b9a4b25c87ed3065827a8))
* **app:** clarify apple and passkey auth failures ([b40e41f](https://github.com/nearlyheadlessarvie/conscia/commit/b40e41f97ced94a6abd4f7148ceda99eb8f5a392))

## [1.1.3](https://github.com/nearlyheadlessarvie/conscia/compare/app/v1.1.2...app/v1.1.3) (2026-05-27)


### Bug Fixes

* **app:** configure ios google sign-in metadata ([dfd8f40](https://github.com/nearlyheadlessarvie/conscia/commit/dfd8f40fd2e80bfe91433027ebb91c0d00b77eab))
* **app:** configure ios google sign-in metadata ([8d11dfb](https://github.com/nearlyheadlessarvie/conscia/commit/8d11dfbc50c6a69b75555deb5d10bd6047fd1a3c))

## [1.1.2](https://github.com/nearlyheadlessarvie/conscia/compare/app/v1.1.1...app/v1.1.2) (2026-05-26)


### Bug Fixes

* **app:** relax ios archive signing inputs ([b1f0d01](https://github.com/nearlyheadlessarvie/conscia/commit/b1f0d01b03b405bfb21cd9b9c75f2a5be08f9a4d))
* **app:** relax ios archive signing inputs ([03695aa](https://github.com/nearlyheadlessarvie/conscia/commit/03695aa488e1e65b6d4a1e5880cdcf6fe9f542e9))

## [1.1.1](https://github.com/nearlyheadlessarvie/conscia/compare/app/v1.1.0...app/v1.1.1) (2026-05-26)


### Bug Fixes

* **app:** resolve android keystore path from android root ([f2b6dd1](https://github.com/nearlyheadlessarvie/conscia/commit/f2b6dd14cd492526e4b612578b2fb3b4def348c6))
* **app:** resolve android keystore path from android root ([02779a8](https://github.com/nearlyheadlessarvie/conscia/commit/02779a83bafea0e4e8b8deb5b02ea2e573ef4e2d))

## [1.1.0](https://github.com/nearlyheadlessarvie/conscia/compare/app/v1.0.0...app/v1.1.0) (2026-05-26)


### Features

* add query versioning and release automation ([4bf0eb5](https://github.com/nearlyheadlessarvie/conscia/commit/4bf0eb5e71de8f77d7a38bbe5c37631aa661e0ad))
* **api:** handle Apple subscription notifications ([0ea883f](https://github.com/nearlyheadlessarvie/conscia/commit/0ea883f4e90c70a957042110da9a514617558833))
* **app:** add admin entitlement operator screen ([7a85e29](https://github.com/nearlyheadlessarvie/conscia/commit/7a85e29e234090eb4f8f3e9a8b4f01b0247cf1e5))
* **app:** add category icon font trial preview ([b4c5305](https://github.com/nearlyheadlessarvie/conscia/commit/b4c530578302e9b07a566014e555bfba99b36e23))
* **app:** add CI release signing config ([f2fe4e3](https://github.com/nearlyheadlessarvie/conscia/commit/f2fe4e330e6aa09dc4102c26872bf86f3e37ac53))
* **app:** add curated category icon svg sources ([46cfbff](https://github.com/nearlyheadlessarvie/conscia/commit/46cfbff9af0b33d3b5ae9e8aef34da75589ed682))
* **app:** add level up celebration screen ([1b22619](https://github.com/nearlyheadlessarvie/conscia/commit/1b22619433768f23b75ad8263e28f1b4c117462a))
* **app:** add looping confetti to level up screen ([81d0b94](https://github.com/nearlyheadlessarvie/conscia/commit/81d0b9445e311e5c108cf778c4ef3a3844e6ea79))
* **app:** add smart nearby suggestions ([a990629](https://github.com/nearlyheadlessarvie/conscia/commit/a990629d3be8d333179592aeecabdd610c4832c1))
* **app:** add smart nearby suggestions ([d7c2c5e](https://github.com/nearlyheadlessarvie/conscia/commit/d7c2c5e11aa268c6315baa3608cd9992a75530de))
* **app:** add transaction date presets ([8b78290](https://github.com/nearlyheadlessarvie/conscia/commit/8b782902c76522ff7b16620cb5ea77d7526898c5))
* **app:** animate dashboard reflect queue locally ([6a1fbe0](https://github.com/nearlyheadlessarvie/conscia/commit/6a1fbe002ce4d78ef160398173b076afdc0e58c2))
* **app:** automate internal and TestFlight releases ([81c126d](https://github.com/nearlyheadlessarvie/conscia/commit/81c126dd76f869336f790260eda978d5f91d770b))
* **app:** expand conscia glyphs and refresh dashboard reflect ([c4aaa56](https://github.com/nearlyheadlessarvie/conscia/commit/c4aaa56daf1f4eb0be95860b945d58339192173c))
* **app:** integrate transaction filters into hero ([6e1addd](https://github.com/nearlyheadlessarvie/conscia/commit/6e1addd65bd584d856488003d60250845ef72858))
* **app:** redesign journey level-up ceremony ([8272251](https://github.com/nearlyheadlessarvie/conscia/commit/82722517d068ac5ac48ca4ddf401b69768ca4257))
* **app:** refine transaction filter rail ([46c89d1](https://github.com/nearlyheadlessarvie/conscia/commit/46c89d19e2e6cb914d96018d5f070058cc8f69cd))
* **app:** render reflect as a visible card deck ([dc5083b](https://github.com/nearlyheadlessarvie/conscia/commit/dc5083b0cf94628a6324d0678e148573d068f2e5))
* **app:** revise transaction filter strip ([882f6ab](https://github.com/nearlyheadlessarvie/conscia/commit/882f6ab5fc69168cf8c8b69eddd9ae61b357397c))
* **app:** trial conscia font icons in category picker ([d31ec33](https://github.com/nearlyheadlessarvie/conscia/commit/d31ec33bc19bbff1721973639783e55c7821130d))
* harden production runtime and add passkeys ([5e77481](https://github.com/nearlyheadlessarvie/conscia/commit/5e77481fec95f2976da49e157829c726c587cee8))
* harden production runtime and add passkeys ([d8bf1b6](https://github.com/nearlyheadlessarvie/conscia/commit/d8bf1b60438a24e0b8e496e58cc50202b59d55f5))


### Bug Fixes

* add android google services plugin ([6958b0a](https://github.com/nearlyheadlessarvie/conscia/commit/6958b0a0c577f32aa8a04bfd8d3cdc09f8ab6b57))
* **app:** add breathing room below transaction hero ([aab845c](https://github.com/nearlyheadlessarvie/conscia/commit/aab845c23bcde0a1d6744fcb1912f905e0601e37))
* **app:** add fading edges to category rails ([9a01baa](https://github.com/nearlyheadlessarvie/conscia/commit/9a01baa2f1b21d34d6d60e66caef222c44091b1a))
* **app:** align adaptive icon background tone ([d53c53e](https://github.com/nearlyheadlessarvie/conscia/commit/d53c53e5d2bbb3a208fe0fa8ca9957b1f634650a))
* **app:** calm dashboard reflect interactions ([aef5de1](https://github.com/nearlyheadlessarvie/conscia/commit/aef5de1e3102fa32ad1247b3578f0a43ab722836))
* **app:** center icons inside compact badges ([be41f2d](https://github.com/nearlyheadlessarvie/conscia/commit/be41f2d681ce6edc3243442f0d22f03053c60935))
* **app:** clarify subscription status in sheet ([963b2ae](https://github.com/nearlyheadlessarvie/conscia/commit/963b2aec74c2919d9c15fc64766596ba6b97c8b5))
* **app:** clear remaining analyzer warnings ([2289ae9](https://github.com/nearlyheadlessarvie/conscia/commit/2289ae9ebdef7068021fa2ef23a02de9e2c86f25))
* **app:** contain notification sheet content ([dce8664](https://github.com/nearlyheadlessarvie/conscia/commit/dce8664c7aabbef70263460b0a166a28682dcff8))
* **app:** enlarge transaction category pills ([b0608e4](https://github.com/nearlyheadlessarvie/conscia/commit/b0608e4df06732d5fa36651ce2a5e7cc5aff4d0c))
* **app:** facelift settings section headers ([c440cc1](https://github.com/nearlyheadlessarvie/conscia/commit/c440cc1fb802da5d8cc2995d9366dfc7ae6fe85d))
* **app:** harden shared conscia empty state ([530d3c1](https://github.com/nearlyheadlessarvie/conscia/commit/530d3c153d6cdaa5bc57ad3843f416bc8f8588c4))
* **app:** harden smart location settings flow ([ed5d83a](https://github.com/nearlyheadlessarvie/conscia/commit/ed5d83a5fb37dedc2851bc768a6b3db12f3f21e0))
* **app:** harden smart location toggle state ([6489105](https://github.com/nearlyheadlessarvie/conscia/commit/6489105f91a7c4fbaf3014313895a6579d83c516))
* **app:** hide and restyle admin entitlements ([b6c0a0c](https://github.com/nearlyheadlessarvie/conscia/commit/b6c0a0cbccd017474a0c3138be7322f6e795ea13))
* **app:** hide insight quests until insights exist ([c7db109](https://github.com/nearlyheadlessarvie/conscia/commit/c7db1098a8246b7d6543344699b53e63bc27e3bb))
* **app:** honor direct web preview routes on startup ([34305d2](https://github.com/nearlyheadlessarvie/conscia/commit/34305d2d9449e3b2a103ca49fbf2e92c665c3554))
* **app:** increase hero to transaction spacing ([4eeea48](https://github.com/nearlyheadlessarvie/conscia/commit/4eeea48cec771258d4fce3e44326725ded63066f))
* **app:** isolate reflect deck transitions ([94ec848](https://github.com/nearlyheadlessarvie/conscia/commit/94ec84880a5fb97a3b5929dcec49439de5bab0ec))
* **app:** keep date filter sheet above dock ([ece6ef3](https://github.com/nearlyheadlessarvie/conscia/commit/ece6ef309e70926a7add66546c564744dd180554))
* **app:** lighten transaction detail category icons ([d8f8630](https://github.com/nearlyheadlessarvie/conscia/commit/d8f8630b3840a7c15a0ef088193b5ee9bc7e23ab))
* **app:** load passkeys web sdk ([10dcfa8](https://github.com/nearlyheadlessarvie/conscia/commit/10dcfa8f3882a5ea3769dec15b79c5dcc4354d40))
* **app:** pin notification sheet header ([00a2e6e](https://github.com/nearlyheadlessarvie/conscia/commit/00a2e6e85ef6ee95ddd646de44aa35e57ba1985f))
* **app:** present date filter sheet above dock ([c1fd1b5](https://github.com/nearlyheadlessarvie/conscia/commit/c1fd1b538ffd4fd15e14176fe7f8de91951cb63c))
* **app:** prevent pinned filter rail overflow ([3b71397](https://github.com/nearlyheadlessarvie/conscia/commit/3b71397c7286eef7ea6a29167e6a79eaa6f1a0a1))
* **app:** prevent receipt picker double launch ([904c329](https://github.com/nearlyheadlessarvie/conscia/commit/904c329eca6fc70e2c25cd1c0932136cc10d249f))
* **app:** refresh admin entitlement access on auth change ([13bb201](https://github.com/nearlyheadlessarvie/conscia/commit/13bb201186fe72963cbe0b4676d080e541f6f06a))
* **app:** refresh journey alert copy ([5ddb561](https://github.com/nearlyheadlessarvie/conscia/commit/5ddb561be5b2fb9341289bb07f16d7c9c4756a39))
* **app:** refresh launcher icon assets ([e4727a0](https://github.com/nearlyheadlessarvie/conscia/commit/e4727a0ee8833f64b357983a5a94fcba2cd7faee))
* **app:** remove dev premium shortcut ([2176cfc](https://github.com/nearlyheadlessarvie/conscia/commit/2176cfc303166985a951d5b8c804c7a365b39429))
* **app:** remove mock nearby merchant suggestions ([da3460f](https://github.com/nearlyheadlessarvie/conscia/commit/da3460f5d2b74e080ae6403c19d44a4802a7bd63))
* **app:** repair selection chip analyzer errors ([11c7c59](https://github.com/nearlyheadlessarvie/conscia/commit/11c7c590cc5277b909800edc8a3dd3e0b19f16e5))
* **app:** restore icon picker expectations and debug build ([51e7315](https://github.com/nearlyheadlessarvie/conscia/commit/51e7315842eaf1c71763a9914af9c10d5eaa7361))
* **app:** smooth app resume recovery ([30efe9a](https://github.com/nearlyheadlessarvie/conscia/commit/30efe9a6f157eecb5a73f20dca0d049e405ea8fa))
* **app:** tighten dashboard reflect deck ([59495f1](https://github.com/nearlyheadlessarvie/conscia/commit/59495f1acc170dd37b97fccb1b411cb814196fc9))
* **app:** tighten pinned date filter label ([b4c1a07](https://github.com/nearlyheadlessarvie/conscia/commit/b4c1a07da7d4e294f3fa5079c8401e8ec174e40a))
* **app:** use insight icon for empty insights state ([4b64c0f](https://github.com/nearlyheadlessarvie/conscia/commit/4b64c0f84296a236af6c9e8fe63a583efed9c5b5))
* **app:** use shared profile section headers ([a7a019d](https://github.com/nearlyheadlessarvie/conscia/commit/a7a019d1fd13a16596de371d741544f52a7908ba))
* **app:** wrap admin entitlement switch tile in material ([0872686](https://github.com/nearlyheadlessarvie/conscia/commit/087268686ed55cde6c453b6a2811d39459b19ed3))
* make smart nearby suggestions device-local ([a613e37](https://github.com/nearlyheadlessarvie/conscia/commit/a613e377b8d1dec9d70ad8ce4958ad0caf67bf74))
* make smart nearby suggestions device-local ([0827c02](https://github.com/nearlyheadlessarvie/conscia/commit/0827c024aa5d5ce925557532b0f6fc1e1f59b5f8))
* productionize recurring and receipt scanning ([836268c](https://github.com/nearlyheadlessarvie/conscia/commit/836268c2fa239d7d293222f27158e8adf5e6dc18))
* remove unused flutter import ([da8ccee](https://github.com/nearlyheadlessarvie/conscia/commit/da8ccee2e1ad97cdf878a8a2b725c58c9cd3aa8a))
* **web:** refresh marketing brand icon surfaces ([ead88bd](https://github.com/nearlyheadlessarvie/conscia/commit/ead88bd343acc4357818e6fde63fa50701c6e542))
