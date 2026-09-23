# AETHRA: Wildbound — INVESTIGATION_LOG

## بيانات التحقيق
- Source baseline: `68d18381078bc8f5f5f2065d72d2d8a5f790f694`
- Fix commits: `c29a30b913a58fafaf8d28dc63d3be6913a4e0be`, `54116fcd640c54f1a25289ace09b920fcd379151`, `91dc1602c726bce5ada133ed4b995e13bc279f6c`.
- Windows runtime run: `35847713744` / Godot 4.7.2.

## [scripts/core/app_root.gd]
- **السبب اللي فتحته لأجله**: نقطة الإقلاع وكل world boot calls
- **شنو يسوي هالملف**: تهيئة الرسوم وJava/auth/menu/network ثم إنشاء العالم واللاعب والـHUD.
- **نقاط خطر لقيتها**:
  - - Java file walk عند إعداد path كبير: ~229-241، synchronous لكنه غير مستدعى بالافتراضي.
- remote avatar load عند ~276 بلا null check، ومساره بعد boot.
- spawn manager load عند 496 غير محمي، لكن runtime أثبته.
- **الحكم النهائي على هالملف**: نظيف بالنسبة للعطل الحالي؛ مشبوه فقط في مسارات لاحقة/اختيارية.

## [scripts/core/app_state.gd]
- **السبب اللي فتحته لأجله**: autoload يستخدمه app_root/UI/player
- **شنو يسوي هالملف**: حالة الجلسة والعالم ونمط اللعب.
- **نقاط خطر لقيتها**:
  - لا توجد نقطة مؤكدة في boot.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/core/settings.gd]
- **السبب اللي فتحته لأجله**: autoload ويحدد first_person/FOV/graphics
- **شنو يسوي هالملف**: إدارة الإعدادات والـinput/persistence.
- **نقاط خطر لقيتها**:
  - first_person=true يكشف عيب view-model لكنه ليس خطأ بحد ذاته.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/audio/audio_manager.gd]
- **السبب اللي فتحته لأجله**: autoload ويُستدعى أثناء gameplay
- **شنو يسوي هالملف**: تحميل وتشغيل الأصوات.
- **نقاط خطر لقيتها**:
  - WASAPI فشل في runner ثم fallback إلى dummy؛ ليس blocker.
- **الحكم النهائي على هالملف**: نظيف بالنسبة للعطل؛ تحذير بيئي غير قاتل.

## [scripts/auth/auth_client.gd]
- **السبب اللي فتحته لأجله**: يبنى قبل القائمة وقد يسبب network wait
- **شنو يسوي هالملف**: حسابات محلية وHTTP auth.
- **نقاط خطر لقيتها**:
  - الطلبات البعيدة عليها timeout؛ الافتراضي auth_server_url فارغ.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/persistence/save_db.gd]
- **السبب اللي فتحته لأجله**: autoload وworld save/load
- **شنو يسوي هالملف**: تخزين العوالم والنسخ الاحتياطية.
- **نقاط خطر لقيتها**:
  - لا مشكلة مؤكدة في boot.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/data/block_registry.gd]
- **السبب اللي فتحته لأجله**: autoload وworld/player
- **شنو يسوي هالملف**: تعريف البلوكات وخواصها.
- **نقاط خطر لقيتها**:
  - لا مشكلة مؤكدة.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/data/item_registry.gd]
- **السبب اللي فتحته لأجله**: autoload وinventory/player
- **شنو يسوي هالملف**: تعريف العناصر والأدوات.
- **نقاط خطر لقيتها**:
  - لا مشكلة مؤكدة.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/data/recipe_registry.gd]
- **السبب اللي فتحته لأجله**: autoload وcrafting
- **شنو يسوي هالملف**: تعريف وصفات التصنيع.
- **نقاط خطر لقيتها**:
  - لا مشكلة مؤكدة.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/network/network_manager.gd]
- **السبب اللي فتحته لأجله**: autoload وربط world/host/join
- **شنو يسوي هالملف**: ENet وRPC validation وحالة اللاعبين.
- **نقاط خطر لقيتها**:
  - remote avatar load غير محمي في مسار remote فقط؛ singleplayer لا ينتظر شبكة.
- **الحكم النهائي على هالملف**: نظيف لمسار singleplayer.

## [scripts/network/server_directory.gd]
- **السبب اللي فتحته لأجله**: autoload وmain_menu
- **شنو يسوي هالملف**: المفضلة والـrecent servers.
- **نقاط خطر لقيتها**:
  - لا network wait عند boot.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/network/remote_player_avatar.gd]
- **السبب اللي فتحته لأجله**: dependency لمسار remote player
- **شنو يسوي هالملف**: نموذج/interpolation للاعب البعيد.
- **نقاط خطر لقيتها**:
  - غير مستدعى في singleplayer smoke.
- **الحكم النهائي على هالملف**: نظيف؛ خارج المسار.

## [scripts/integration/java_engine_bridge.gd]
- **السبب اللي فتحته لأجله**: app_root يستدعيه قبل القائمة
- **شنو يسوي هالملف**: فحص مسارات Java/Minecraft bridge.
- **نقاط خطر لقيتها**:
  - recursive file walk synchronous إذا path غير فارغ؛ ليس سبب العطل مع defaults.
- **الحكم النهائي على هالملف**: مشبوه بس مو مؤكد؛ يحتاج اختبار path ضخم مستقل.

## [scripts/ui/ui_factory.gd]
- **السبب اللي فتحته لأجله**: dependency مباشر للقائمة/HUD
- **شنو يسوي هالملف**: safe make_icon/make_avatar مع null/can_instantiate fallback.
- **نقاط خطر لقيتها**:
  - لا مشكلة.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/ui/vector_icon.gd]
- **السبب اللي فتحته لأجله**: UIFactory dependency
- **شنو يسوي هالملف**: رسم icons بالـvector.
- **نقاط خطر لقيتها**:
  - لا IO/await حاجز.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/ui/avatar_renderer.gd]
- **السبب اللي فتحته لأجله**: UIFactory dependency
- **شنو يسوي هالملف**: رسم avatar preview.
- **نقاط خطر لقيتها**:
  - لا مشكلة.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/ui/main_menu.gd]
- **السبب اللي فتحته لأجله**: يبني القائمة وزر ابدأ اللعب
- **شنو يسوي هالملف**: backdrop/sidebar/pages/auth/world cards/navigation.
- **نقاط خطر لقيتها**:
  - _animate_intro الآن يجعل visible/alpha=1 قبل الـTween مع safety timer؛ لا blocker. بعض asset loads أثبتها import/runtime.
- **الحكم النهائي على هالملف**: نظيف بالنسبة لعطل القائمة.

## [scripts/ui/settings_menu.gd]
- **السبب اللي فتحته لأجله**: يغير first_person/FOV/settings
- **شنو يسوي هالملف**: صفحة الإعدادات.
- **نقاط خطر لقيتها**:
  - قبل الإصلاح: camera position فقط. الآن السطور 367-370 تستدعي _apply_view_mode مع fallback.
- **الحكم النهائي على هالملف**: تم إصلاح المشكلة المؤكدة المرتبطة بتبديل منظور الكاميرا.

## [scripts/ui/hud.gd]
- **السبب اللي فتحته لأجله**: المستخدم رأى FPS فقط
- **شنو يسوي هالملف**: HUD والصحة/الـhotbar والـcrosshair وFPS.
- **نقاط خطر لقيتها**:
  - FPS حقيقي عبر Engine.get_frames_per_second؛ لا blocker.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/player/player_avatar.gd]
- **السبب اللي فتحته لأجله**: يبني player/head/camera ويُستخدم بعد world init
- **شنو يسوي هالملف**: الحركة والقتال والتعدين والبناء والكاميرا.
- **نقاط خطر لقيتها**:
  - قبل الإصلاح: model مرئي، head y=2.02، camera داخل الرأس، cull disabled. السطور 36-46 + 56-63 كانت self-occlusion مؤكدة.
- **الحكم النهائي على هالملف**: فيه مشكلة مؤكدة وتم إصلاحها: السطر 64 يستدعي _apply_view_mode؛ الدالة 144-151 تخفي local model في first-person؛ V عند 180-183 يستخدم نفس الدالة.

## [scripts/gameplay/inventory.gd]
- **السبب اللي فتحته لأجله**: ينشئه player ويستخدمه gameplay
- **شنو يسوي هالملف**: slots/select/add/remove/count.
- **نقاط خطر لقيتها**:
  - لا مشكلة مؤكدة.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/gameplay/survival.gd]
- **السبب اللي فتحته لأجله**: يُستدعى كل frame من player
- **شنو يسوي هالملف**: health/hunger/stamina/xp.
- **نقاط خطر لقيتها**:
  - لا مشكلة مؤكدة.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/gameplay/crafting.gd]
- **السبب اللي فتحته لأجله**: مسار crafting/self-test
- **شنو يسوي هالملف**: recipe consumption/output.
- **نقاط خطر لقيتها**:
  - لا مشكلة مؤكدة.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/world/voxel_world.gd]
- **السبب اللي فتحته لأجله**: يبدأ بعد ابدأ اللعب
- **شنو يسوي هالملف**: generator/spawn chunk/mesh/collision/streaming.
- **نقاط خطر لقيتها**:
  - threads تُنتظر عند exit؛ spawn chunk synchronous؛ لا await world_ready حاجز.
- **الحكم النهائي على هالملف**: نظيف؛ runtime أثبت generation/render.

## [scripts/world/voxel_chunk.gd]
- **السبب اللي فتحته لأجله**: يبني terrain mesh
- **شنو يسوي هالملف**: ArrayMesh/face culling/collision/vertex colors.
- **نقاط خطر لقيتها**:
  - لا مشكلة مؤكدة؛ لا يعتمد على PNG atlas المعطوب السابق.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/world/world_generator.gd]
- **السبب اللي فتحته لأجله**: يولد block data
- **شنو يسوي هالملف**: FastNoise terrain/caves/sea/biomes/structures.
- **نقاط خطر لقيتها**:
  - bounds وdynamic height سليمة؛ لا مشكلة spawn مؤكدة.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/world/world_time.gd]
- **السبب اللي فتحته لأجله**: dependency للـlighting/time
- **شنو يسوي هالملف**: day cycle/weather.
- **نقاط خطر لقيتها**:
  - الوصول إلى lighting_built في runtime يثبت عدم التعليق.
- **الحكم النهائي على هالملف**: نظيف.

## [scripts/entities/spawn_manager.gd]
- **السبب اللي فتحته لأجله**: ينشئه app_root بعد player
- **شنو يسوي هالملف**: creature spawning.
- **نقاط خطر لقيتها**:
  - load creature script لاحق؛ ليس boot blocker.
- **الحكم النهائي على هالملف**: نظيف لمسار العطل.

## [scripts/entities/creature.gd]
- **السبب اللي فتحته لأجله**: dependency لـspawn manager
- **شنو يسوي هالملف**: AI/physics/damage مبسط.
- **نقاط خطر لقيتها**:
  - لا مشكلة مؤكدة.
- **الحكم النهائي على هالملف**: نظيف.

## [scenes/main.tscn]
- **السبب اللي فتحته لأجله**: main_scene
- **شنو يسوي هالملف**: Node3D root مع app_root.gd.
- **نقاط خطر لقيتها**:
  - لا مشكلة.
- **الحكم النهائي على هالملف**: نظيف.

## [project.godot]
- **السبب اللي فتحته لأجله**: أول ملف في التحقيق
- **شنو يسوي هالملف**: main_scene، rendering، autoloads، input/environment.
- **نقاط خطر لقيتها**:
  - main_scene صحيح؛ autoloads كاملة لمسار العميل.
- **الحكم النهائي على هالملف**: نظيف.

## [tests/parse_all_scripts.gd]
- **السبب اللي فتحته لأجله**: GDScript load gate
- **شنو يسوي هالملف**: تحميل/instantiate scripts.
- **نقاط خطر لقيتها**:
  - نجح في run 402.
- **الحكم النهائي على هالملف**: نظيف.

## [tests/self_test.gd]
- **السبب اللي فتحته لأجله**: logic smoke gate
- **شنو يسوي هالملف**: registries/world bounds/inventory/crafting.
- **نقاط خطر لقيتها**:
  - لا يكتشف visual occlusion بمفرده؛ gap وليس bug في logic.
- **الحكم النهائي على هالملف**: نظيف لكن غير كافٍ بصريًا.

## [tests/java_engine_bridge_test.gd]
- **السبب اللي فتحته لأجله**: اختبار Java integration
- **شنو يسوي هالملف**: اختبار bridge detection.
- **نقاط خطر لقيتها**:
  - خارج F5 normal client boot.
- **الحكم النهائي على هالملف**: نظيف؛ غير مستدعى بالإقلاع.

## [tests/runtime_visual_smoke.gd]
- **السبب اللي فتحته لأجله**: الدليل الرسومي
- **شنو يسوي هالملف**: menu + start-game + world + screenshots + boot log.
- **نقاط خطر لقيتها**:
  - قبل الإصلاح كان يكتفي بوجود chunk/player/camera؛ الآن السطور 56-74 تتحقق من local model ومن pixel coverage.
- **الحكم النهائي على هالملف**: تم إصلاح false PASS في الاختبار.

## [server/main_server.gd]
- **السبب اللي فتحته لأجله**: server-only
- **شنو يسوي هالملف**: headless server process.
- **نقاط خطر لقيتها**:
  - لا يدخل main_scene.
- **الحكم النهائي على هالملف**: غير مستدعى بالإقلاع — تم تجاوزه عمدًا.

## [server/main_server.tscn]
- **السبب اللي فتحته لأجله**: server-only scene
- **شنو يسوي هالملف**: مشهد السيرفر.
- **نقاط خطر لقيتها**:
  - لا يدخل F5 client.
- **الحكم النهائي على هالملف**: غير مستدعى بالإقلاع — تم تجاوزه عمدًا.

## [server/auth-service/main.go]
- **السبب اللي فتحته لأجله**: خدمة auth منفصلة
- **شنو يسوي هالملف**: HTTP/SQLite service.
- **نقاط خطر لقيتها**:
  - لا يدخل Godot client boot.
- **الحكم النهائي على هالملف**: غير مستدعى بالإقلاع — تم تجاوزه عمدًا.

## [server/auth-service/main_test.go]
- **السبب اللي فتحته لأجله**: اختبار Go للخدمة
- **شنو يسوي هالملف**: اختبارات auth service.
- **نقاط خطر لقيتها**:
  - لا يدخل Godot client boot.
- **الحكم النهائي على هالملف**: غير مستدعى بالإقلاع — تم تجاوزه عمدًا.

## [server/auth-service/go.mod]
- **السبب اللي فتحته لأجله**: Go module
- **شنو يسوي هالملف**: dependencies/version.
- **نقاط خطر لقيتها**:
  - لا يدخل Godot client boot.
- **الحكم النهائي على هالملف**: غير مستدعى بالإقلاع — تم تجاوزه عمدًا.

## [server/database_schema.sql]
- **السبب اللي فتحته لأجله**: server database
- **شنو يسوي هالملف**: schema.
- **نقاط خطر لقيتها**:
  - لا يقرأه client F5.
- **الحكم النهائي على هالملف**: غير مستدعى بالإقلاع — تم تجاوزه عمدًا.

## [server/server_config.example.json]
- **السبب اللي فتحته لأجله**: server config example
- **شنو يسوي هالملف**: مثال إعداد.
- **نقاط خطر لقيتها**:
  - لا يقرأه client F5.
- **الحكم النهائي على هالملف**: غير مستدعى بالإقلاع — تم تجاوزه عمدًا.

## [ملفات .uid + docs/build/config/import]
- **السبب اللي فتحته لأجله**: metadata/documentation
- **شنو يسوي هالملف**: Godot metadata/build/docs.
- **نقاط خطر لقيتها**:
  - لا منطق runtime مستقل داخل call graph.
- **الحكم النهائي على هالملف**: غير مستدعاة بالإقلاع — تم تجاوزها عمدًا.

## مطابقة التشغيل الفعلي
- `main_menu_built` عند 1068ms و`boot_complete` عند 1070ms.
- `world_start` 2410ms، `world_initialized` 2588ms، `player_camera_ready` 2658ms، `world_boot_complete` 2762ms.
- بعد إصلاح player model، لقطة العالم الجديدة تحتوي terrain غير أسود، والـvisual smoke يتحقق من ذلك آليًا.

## آخر boot_log فعلي
\`\`\`text
AETHRA boot log
0ms boot_start
8ms window_restored
16ms lighting_built
19ms graphics_applied
25ms java_backend_checked
42ms auth_initialized
1068ms main_menu_built
1070ms network_presence_ready
1070ms boot_complete
2410ms world_start
2588ms world_initialized
2658ms player_camera_ready
2762ms world_boot_complete
\`\`\`

## أخطاء/تحذيرات لا يتم إخفاؤها
- Windows runner استخدم Microsoft Basic Render Driver/ANGLE.
- WASAPI فشل ثم dummy audio.
- ظهرت رسائل cleanup/leak لبعض RIDs/ObjectDB/resources عند exit. لم تفشل الـsmoke، لكنها ليست مصححة كحالة صفر warnings/errors على كل جهاز.

## التعديلات
1. `scripts/player/player_avatar.gd:64,144-151,180-183`: إضافة _apply_view_mode وإخفاء local player mesh في first-person وربط V به.
2. `scripts/ui/settings_menu.gd:367-370`: مزامنة إعداد camera مع _apply_view_mode.
3. `tests/runtime_visual_smoke.gd:56-74`: رفض حالة local model visible أو screenshot black بدل false PASS.
4. CI يلتقط Windows desktop proof في smoke-start إن كانت شاشة النظام متاحة.

## الحكم النهائي
العطل الأصلي المؤكد هو self-occlusion من نموذج اللاعب المحلي داخل كاميرا first-person، وتم إصلاحه والتحقق منه على Windows runtime. التصدير شُغّل فعليًا و`PROCESS_START_OK`، لكن full desktop GUI automation وحفظ/إعدادات/Multiplayer end-to-end ليست مثبتة كاختبار بشري كامل في runner الحالي.


## Additional finding from run 407
- **tests/runtime_visual_smoke.gd**: Godot 4.7.2 reported a parse error at the newly added third-person proof variable because `:=` could not infer the type returned by `Node.get()`. The variable is now explicitly declared as `Variant` (current line 70-ish). This was a test-script compile issue, not a gameplay runtime failure.
- The player/world fix itself had already passed the graphical smoke in run 402; this later failure existed only because the stricter evidence test was not type-correct.
