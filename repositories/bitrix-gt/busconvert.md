Скрипт busconvert_11.php работает без проблем на percona mysql 5.7 / 8.0.  
На mariadb 10.11 на свежеустановленном портале падает с ошибкой на этом шаге:

```sql
ALTER TABLE b_lang MODIFY LID char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT  NULL ;
ERROR 1833 (HY000): Cannot change column 'LID': used in a foreign key constraint 'bitrix/b_learn_course_site_ibfk_2' of table 'bitrix/b_learn_course_site'
```

Попытка отключить проверку на время конвертации не помогла ```SET FOREIGN_KEY_CHECKS = 0;```

Тут нужно вручную удалять ключи и добавлять обратно.

```sql
ALTER TABLE `b_learn_course_site` DROP FOREIGN KEY `b_learn_course_site_ibfk_2`;
ALTER TABLE `b_list_rubric` DROP FOREIGN KEY `b_list_rubric_ibfk_1`;
ALTER TABLE `b_xdi_lf_scheme` DROP FOREIGN KEY `b_xdi_lf_scheme_ibfk_1`;
```

Модифицируем
```sql
ALTER TABLE `b_lang` MODIFY `LID` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;
```

И добавляем ключи обратно.
```sql
CREATE INDEX idx_b_lang_LID ON `b_lang` (`LID`);
ALTER TABLE `b_learn_course_site` MODIFY `SITE_ID` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;
ALTER TABLE `b_learn_course_site` ADD CONSTRAINT `b_learn_course_site_ibfk_2` FOREIGN KEY (`SITE_ID`) REFERENCES `b_lang` (`LID`);


ALTER TABLE `b_list_rubric` MODIFY `LID` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;
ALTER TABLE `b_list_rubric` ADD CONSTRAINT `b_list_rubric_ibfk_1` FOREIGN KEY (`LID`) REFERENCES `b_lang` (`LID`);

ALTER TABLE `b_xdi_lf_scheme` MODIFY `LID` char(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL;
ALTER TABLE `b_xdi_lf_scheme` ADD CONSTRAINT `b_xdi_lf_scheme_ibfk_1` FOREIGN KEY (`LID`) REFERENCES `b_lang` (`LID`);
```

В других таблицах проблем не возникло и скрипт смог завершить конвертацию.
