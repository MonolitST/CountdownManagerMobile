# CountdownManagerMobile

Нативное приложение на SwiftUI. Минимальная версия — iOS 18. Проект открывается в Xcode 26, а таргеты компилируются в режиме Swift 6. При выборе API сверяй эти ограничения. Возможности iOS 26, включая Liquid Glass, подключай через проверку доступности и сохраняй рабочий интерфейс для iOS 18.

## Swift Agent Skills

Для каждой задачи открой `SKILL.md` подходящего скилла, затем прочитай нужные разделы из его `references/`. Для задач на стыке областей можно сочетать несколько скиллов. Учитывай инструкции проекта при применении рекомендаций из общего каталога. [Источники и версии](.agents/skills/README.md)

| Задача | Скилл и разделы |
| --- | --- |
| Экран, форма, навигация, темы или локализация | [SwiftUI Pro](.agents/skills/swiftui-pro/SKILL.md). Выбери раздел по задаче, например [навигация](.agents/skills/swiftui-pro/references/navigation.md), [API](.agents/skills/swiftui-pro/references/api.md) или [локализация](.agents/skills/swiftui-pro/references/localization.md). |
| Разделение ответственности, зависимости или новое состояние | [Swift Architecture](.agents/skills/swift-architecture-skill/SKILL.md). Для приложения начни с [MVVM](.agents/skills/swift-architecture-skill/references/mvvm.md) и [Observation](.agents/skills/swift-architecture-skill/references/observation.md). |
| Async/await, отмена задач, делегаты или диагностика гонок | [Swift Concurrency Pro](.agents/skills/swift-concurrency-pro/SKILL.md). Используй [изоляцию акторов](.agents/skills/swift-concurrency-pro/references/actors.md), [отмену](.agents/skills/swift-concurrency-pro/references/cancellation.md) или [мосты для callback API](.agents/skills/swift-concurrency-pro/references/bridging.md). |
| Тесты моделей, репозитория и асинхронного кода | [Swift Testing Pro](.agents/skills/swift-testing-pro/SKILL.md). Начни с [основных правил](.agents/skills/swift-testing-pro/references/core-rules.md), при необходимости открой [асинхронные тесты](.agents/skills/swift-testing-pro/references/async-tests.md). |
| VoiceOver, Dynamic Type и доступность новых контролов | [iOS Accessibility](.agents/skills/ios-accessibility/SKILL.md). Разделы для SwiftUI описывают [VoiceOver](.agents/skills/ios-accessibility/references/voiceover-swiftui.md) и [Dynamic Type](.agents/skills/ios-accessibility/references/dynamic-type-swiftui.md). |
| Медленная отрисовка, задержки, прокрутка или память | [SwiftUI Performance Audit](.agents/skills/swiftui-performance-audit/SKILL.md). Начни с конкретного симптома, проверь [типовые причины](.agents/skills/swiftui-performance-audit/references/code-smells.md) и используй замеры, если нужен профиль. |
| Таймер на экране блокировки и в Dynamic Island | [Widgets](.agents/skills/widgets/SKILL.md). Открой [Live Activities](.agents/skills/widgets/references/live-activities.md) и, если меняется переход в приложение, [навигацию](.agents/skills/widgets/references/deep-linking-and-navigation.md). |

## Работа с кодом

- Сохраняй границы MVVM. В `CountdownManagerMobile/Domain` находятся модели и правила. SwiftUI-экраны отображают состояние и передают действия. ViewModel ведёт состояние интерфейса. Доступ к SQLite идёт через `PlannerRepository`, реализация на GRDB находится в `Data/Persistence`.
- Используй существующие компоненты и цвета из `Design`. Обновляй английские и русские строки в соответствующем `Localizable.xcstrings`, включая строки расширений и подписи доступности. Для анимаций учитывай «Уменьшение движения».
- Для изменений схемы дополняй `PlannerDatabaseMigration` новой миграцией. Сохраняй UUID записей, порядок чек-листов и семантику дат и расписаний. Храни метаданные вложений в SQLite, а сами файлы отдельно. Учитывай общую базу приложения и `PlanShareExtension` в App Group и проверяй согласованность файлов и записей при сохранении и отмене.
- При работе с `FocusActivityExtension` и `PlanShareExtension` проверяй доступность API для расширений. Общие атрибуты Live Activity находятся в `FocusActivityShared`.

## Проверка

- Используй схему `CountdownManagerMobile`. Для сборки и проверки сценариев на симуляторе предпочитай MobileBuildMCP, когда он доступен. Также можно использовать Xcode или `xcodebuild` и `xcrun simctl`.
- Тесты в `CountdownManagerMobileTests` используют Swift Testing. Проверяй затронутую логику модели и хранилища. Для изменений интерфейса проходи затронутый сценарий на симуляторе и сверяй его с Figma, если задача содержит макет. Проверяй соответствующие языки, темы и настройки доступности.
- Для проверки миграций и «Поделиться» используй тестовые данные или изолированный симулятор. В итоге укажи, что действительно удалось собрать и проверить.

## App Store и App Review

| Задача | Скилл и разделы |
| --- | --- |
| Аудит приложения и материалов перед App Review | [App Store Review](.agents/skills/appstore-review/SKILL.md) и [справочник по требованиям Apple](.agents/skills/appstore-review/references/appstore-review-ref.md). Используй при явном запросе на проверку готовности к App Review. |
| Команды и работа с App Store Connect через `asc` | [App Store Connect CLI](.agents/skills/asc-cli-usage/SKILL.md). |
| Подготовка версии, загрузка сборки и отправка на ревью | [App Store Release Flow](.agents/skills/asc-release-flow/SKILL.md). |
| Проверка версии в App Store Connect, статус заявки или разбор отклонения | [App Store Submission Health](.agents/skills/asc-submission-health/SKILL.md). При необходимости открой справки по [блокирующим ошибкам](.agents/skills/asc-submission-health/references/readiness-repairs.md) и [App Privacy](.agents/skills/asc-submission-health/references/app-privacy.md). |

- При аудите сверяйся с актуальными [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) и [предстоящими требованиями Apple](https://developer.apple.com/news/upcoming-requirements/). Отмечай проверки, которым нужны сборка, данные App Store Connect или доступ к устройству.
- Для CountdownManagerMobile проверь материалы релиза на русском и английском, описание использования геолокации для Open-Meteo, уведомления и работу обоих расширений. В архиве сверь версии и номера сборки приложения, `FocusActivityExtension` и `PlanShareExtension`. Проверь доступ Share Extension к App Group.
- Загружай сборки, меняй данные App Store Connect, отправляй заявку и выпускай версию в рамках явно запрошенных действий. Ключи App Store Connect храни вне репозитория.
