# Countdown Manager для App Store

Метаданные первого релиза 1.0 для iPhone и iPad. Проверено 27 ноября 2026 года.

- [Русская карточка](ru.md)
- [Английская карточка · English (U.S.)](en-US.md)
- [Заметки для App Review](review-notes.md)
- Политика конфиденциальности · [Русский](privacy/ru.md) · [English](privacy/en-US.md)
- Поддержка · [Русский](support/ru.md) · [English](support/en-US.md)
- [Скриншоты iPhone и iPad для App Store](screenshots/README.md)

## Позиционирование

Обратный отсчёт для людей, которым нужно подготовиться к поездке, празднику или дедлайну. Первый экран показывает оставшиеся дни, а в самом плане лежат чек-лист и материалы. Это главный сценарий и для описания, и для скриншотов.

- **Название** сохраняет бренд Countdown Manager и добавляет понятный тип приложения в каждой локали. Доступность обоих вариантов названия нужно проверить в App Store Connect.
- **Подзаголовок** добавляет ключевую пользу. В русской карточке это обратный отсчёт и напоминания, в английской — чек-листы, напоминания и фокус.
- **Ключевые слова** покрывают типы событий, подготовку и таймер. Наборы собраны по функциям приложения и формулировкам в карточках конкурентов. Частотность запросов и позиции в поиске пока не измерялись.
- **Категория** — предложенная основная категория Productivity. Предложенный основной язык карточки — English (U.S.) с отдельной русской локализацией. [Категории Apple](https://developer.apple.com/app-store/categories/) · [Локализации App Store](https://developer.apple.com/help/app-store-connect/reference/app-information/app-store-localizations/)

## Карточки для сравнения

| Приложение | Акцент в карточке | Что показать у Countdown Manager |
| --- | --- | --- |
| Countdown Events | Дни до события, оформление и виджеты обратного отсчёта. | Открыть событие и показать список дел с прогрессом. [App Store US](https://apps.apple.com/us/app/countdown-events-widgets/id6759694899) |
| Structured | Расписание дня, задачи, таймлайн и фокус. | На первом скриншоте показать конкретную будущую дату и оставшиеся дни. [App Store US](https://apps.apple.com/us/app/structured-daily-planner-todo/id1499198946) |
| Countdown Moments | Важные даты, планы и воспоминания. | Показать, как PDF, фото и ссылки помогают подготовиться к событию. [App Store RU](https://apps.apple.com/ru/app/%D0%BE%D0%B1%D1%80%D0%B0%D1%82%D0%BD%D1%8B%D0%B9-%D0%BE%D1%82%D1%81%D1%87%D1%91%D1%82/id6834374515) |

## Скриншоты

Первые три кадра показывают отсчёт, чек-лист и напоминания. Они дают основные причины скачать приложение, даже если в выдаче видна только часть галереи. [Готовые снимки](screenshots/README.md) содержат реальные экраны Release-сборки с тестовыми данными. В таблице ниже приведены подписи для оформления карточки. [Поиск в App Store](https://developer.apple.com/app-store/search/) · [Размеры скриншотов](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)

| Кадр | Что снять | Русская подпись | English caption |
| --- | --- | --- | --- |
| 1 | «Мои планы» с выделенной поездкой и видимым отсчётом до неё. | Считайте дни до важных дат | Count down to important dates |
| 2 | План поездки с чек-листом, где отмечены два пункта. | Соберите всё по чек-листу | Get ready with a checklist |
| 3 | «Напоминания» с одним разовым и одним повторяющимся напоминанием. | Настройте напоминания | Set one-time or repeating reminders |
| 4 | План с PDF бронирования, фото и веб-ссылкой. | Храните фото, PDF и ссылки в плане | Keep photos, PDFs, and links together |
| 5 | Запущенный таймер на экране приложения с названием плана. | Выделите время на подготовку | Make time to focus |
| 6 | Редактор плана с датой, заметкой, чек-листом и вложениями. | Соберите план под себя | Make the plan your own |

## Перед заполнением App Store Connect

- В страницах поддержки и конфиденциальности заменить `{{SUPPORT_EMAIL}}` на рабочий адрес, а `{{DEVELOPER_NAME}}` — на имя или юридическое наименование разработчика. Дополнить контакты по требованиям выбранных регионов.
- Опубликовать обе локали на общедоступных страницах и указать их в **Support URL** и **Privacy Policy URL**. Добавить доступную ссылку на политику внутри приложения. В **App Privacy** сверить фактическое использование погоды, геолокации и сторонних SDK. [Поля App Store Connect](https://developer.apple.com/help/app-store-connect/reference/app-information/app-and-compliance-information/) · [App Privacy](https://developer.apple.com/app-store/app-privacy-details/) · [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/#privacy)
- Загрузить локализованные скриншоты и проверить их порядок. Для первого выпуска поле **What’s New** недоступно. Для анонса используйте **Promotional Text** из карточки. [Поля версии](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)
- Добавить заметки для ревью, контакт ответственного и заполнить возрастной рейтинг при подготовке карточки. [Поля ревью](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/) · [Возрастной рейтинг](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/)

## Проверка полей

Проверены символы для видимых полей и байты UTF‑8 для ключевых слов. Лимиты взяты из App Store Connect Help. [Поля приложения](https://developer.apple.com/help/app-store-connect/reference/app-information/app-and-compliance-information/) · [Поля версии](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)

| Поле | Русский | English (U.S.) | Лимит |
| --- | ---: | ---: | ---: |
| App Name | 24 | 26 | 30 символов |
| Subtitle | 29 | 29 | 30 символов |
| Promotional Text | 120 | 125 | 170 символов |
| Description | 1164 | 1150 | 4 000 символов |
| Keywords | 97 | 96 | 100 байт |

Методика и валидатор — [App Store ASO Skill, Tim Broddin](https://github.com/TimBroddin/skills/tree/2549b676c30e4ded58fc9ab050b5bcd8d98b15a2/skills/app-store-aso). Для полей версии и материалов использован раздел 2 скилла [App Store Review](../../.agents/skills/appstore-review/SKILL.md).
