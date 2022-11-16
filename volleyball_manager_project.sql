/* Database of Russian Volleyball Championship manager(Men Superleague).
   База данных волейбольного менеджера предназначена для хранения и обработки информации при проведении
   Российского волейбольного чемпионата Суперлиги (при необходимости можеть быть развернута и на другие чемпионаты/лиги).
   В базе собирается информация о клубах, командах, игроках с их профилями, а также расписание
   предстоящих игр чемпионата и результаты прошедших игр, которые заносятся в общую сводную таблицу
   на каждом этапе соревнований.
*/

DROP DATABASE IF EXISTS volleyball_manager;
CREATE DATABASE volleyball_manager;
USE volleyball_manager;

DROP TABLE IF EXISTS clubs;
/* В таблицу clubs также могут быть включены и национальные сборные, которые в свою очередь заявляют свои команды
   для участия в международных чемпионатах.
*/
CREATE TABLE clubs (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	hometown VARCHAR(100) COMMENT 'Город базирования клуба',
	arena_name VARCHAR(255) COMMENT 'Основной комплекс базирования клуба',
	president VARCHAR(100) COMMENT 'Глава клуба',
	foundation_year YEAR,
	
	UNIQUE name_hometown_unidx(name, hometown(10))
);

DROP TABLE IF EXISTS teams;
/* При развертывании базы на чемпионаты и среди других лиг, в том числе молодежной, а также для участия в международных
   соревнованиях от одного клуба может быть заявлено несколько команд.
*/
CREATE TABLE teams (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(100) NOT NULL UNIQUE COMMENT 'Как правило: имя_клуба(город)',
	club_id INT UNSIGNED NOT NULL COMMENT 'id клуба, от которого заявлена команда',
	head_coach VARCHAR(100) COMMENT 'Главный тренер команды',
	
	FOREIGN KEY (club_id) REFERENCES clubs(id)
);

DROP TABLE IF EXISTS competitions;
/* В рамках данного проекта рассматривается только Российский чемпионат среди команд Суперлиги, но база данных предусматривает
   добавление и других чемпионатов, турниров, кубков.
 */
CREATE TABLE competitions (
	id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR(255),
	description TEXT COMMENT 'Схема, этапы, место и сроки проведения, инициатор соревнования и т.д.'
);

DROP TABLE IF EXISTS team_requests;
/* В этой таблице хранятся заявки команд на участие в турнирах каждого сезона.
 */
CREATE TABLE team_requests (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	competition_id SMALLINT UNSIGNED NOT NULL,
	team_id INT UNSIGNED NOT NULL,
	season YEAR COMMENT 'Год окончания сезона',
	
	FOREIGN KEY (competition_id) REFERENCES competitions(id),
	FOREIGN KEY (team_id) REFERENCES teams(id)
) COMMENT 'Заявки команд на участие в турнирах';

DROP TABLE IF EXISTS players;
/* Основная информация об игроках в таблицах players и profiles.
 */
CREATE TABLE players (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
	firstname VARCHAR(100),
	lastname VARCHAR(100),
	main_role ENUM('setter', 'libero', 'outside hitter', 'opposite hitter', 'middle blocker') COMMENT 'Основное игровое амплуа',
	playing_number TINYINT UNSIGNED COMMENT 'Игровой номер',
	club_id INT UNSIGNED NOT NULL COMMENT 'id клуба, с которым у игрока заключен контракт',
	
	KEY players_firstname_lastname_idx(firstname, lastname),
	FOREIGN KEY (club_id) REFERENCES clubs(id)
);

DROP TABLE IF EXISTS team_lineups;
/* Составы команд в сезоне, привязанные к request_id (id заявки).
 */
CREATE TABLE team_lineups (
	request_id BIGINT UNSIGNED NOT NULL,
	player_id INT UNSIGNED NOT NULL,
	
	FOREIGN KEY (request_id) REFERENCES team_requests(id),
	FOREIGN KEY (player_id) REFERENCES players(id),
	PRIMARY KEY request_id_player_id_unidx(request_id, player_id)
) COMMENT 'Составы команд';

DROP TABLE IF EXISTS profiles;
CREATE TABLE profiles (
	player_id INT UNSIGNED NOT NULL,
	gender BIT COMMENT '1 - male, 0 - female',
	birthday DATE,
	birthplace VARCHAR(100),
	height SMALLINT UNSIGNED COMMENT 'Рост в сантиметрах',
	career TEXT COMMENT 'Карьера',
	achievements TEXT COMMENT 'Достижения',
	
	FOREIGN KEY (player_id) REFERENCES players(id)
) COMMENT 'Профили игроков';

DROP TABLE IF EXISTS games_schedule;
/* В эту таблицу сводится расписание всех игр всех соревнований. Сортируя по game_date и фильтруя по competition_id и competition_stage,
   можно просматривать хронологию игр по текущему турниру и этапу в нем.
 */
CREATE TABLE games_schedule (
	game_date DATE,
	home_team_id INT UNSIGNED NOT NULL COMMENT 'id домашней команды',
	guest_team_id INT UNSIGNED NOT NULL COMMENT 'id гостевой команды',
	competition_id SMALLINT UNSIGNED NOT NULL COMMENT 'id соревнования, в рамках которого проводится игра',
	competition_stage VARCHAR(255) NOT NULL COMMENT 'Этап соревнования',
	game_place VARCHAR(255) COMMENT 'Место проведения игры: arena_name(hometown). В регулярных чемпионатах, как правило, это комплекс базирования домашний команды',
	
	UNIQUE date_home_guest_id_unidx(game_date, home_team_id, guest_team_id),
	FOREIGN KEY (home_team_id) REFERENCES teams(id),
	FOREIGN KEY (guest_team_id) REFERENCES teams(id),
	FOREIGN KEY (competition_id) REFERENCES competitions(id)
) COMMENT 'Расписание игр';

DROP TABLE IF EXISTS games_results;
/* В эту таблицу сводятся результаты всех проведенных игр из game_schedule.
 */
CREATE TABLE games_results (
	game_date DATE,
	home_team_id INT UNSIGNED NOT NULL COMMENT 'id домашней команды',
	guest_team_id INT UNSIGNED NOT NULL COMMENT 'id гостевой команды',
	competition_id SMALLINT UNSIGNED NOT NULL COMMENT 'id соревнования, в рамках которого проводится игра',
	competition_stage VARCHAR(255) NOT NULL COMMENT 'Этап соревнования',
	score ENUM('3:0', '3:1', '3:2', '2:3', '1:3', '0:3'),
	extended_score VARCHAR(100) COMMENT 'Счет в каждой партии. Например: 25:23, 18:25, 28:26, 24:26, 19:17',
	
	UNIQUE date_home_guest_id_unidx(game_date, home_team_id, guest_team_id),
	FOREIGN KEY (home_team_id) REFERENCES teams(id),
	FOREIGN KEY (guest_team_id) REFERENCES teams(id),
	FOREIGN KEY (competition_id) REFERENCES competitions(id)
) COMMENT 'Результаты игр';

/* Заполним базу актуальной информацией.*/

INSERT INTO clubs (name, hometown, arena_name, president, foundation_year) VALUES
	('Зенит', 'Казань', 'Центр волейбола "Санкт-Петербург"', 'Кантюков Рафкат', '2000'),
	('Зенит', 'Санкт-Петербург', 'Академия волейбола Вячеслава Платонова', 'Самсонов Владимир Васильевич', '2017'),
	('Динамо', 'Москва', 'Волейбольная арена "Динамо"', 'Шекин Михаил Васильевич', '1923'),
	('Локомотив', 'Новосибириск', 'СК "Локомотив-Арена"', 'Гончаров Вадим Вадимович', '1977'),
	('Белогорье', 'Белгород', 'ДС "Космос"', 'Шипулин Геннадий Яковлевич', '1976'),
	('Кузбасс', 'Кемерово', 'СРК "Арена"', 'Мазикин Валенитин Петрович', '2008'),
	('Динамо-ЛО', 'Сосновый Бор', 'СК "Центр олимпийской подготовки по влейболу"', 'Патрушев Алексей Викторович', '2004'),
	('Факел', 'Новый Уренгой', 'ДС "Звездный"', 'Капранов Николай Васильевич', '1984'),
	('Урал', 'Уфа', 'СДК "Динамо"', 'Багметов Валерий Николаевич', '1977'),
	('Югра-Самотлор', 'Нижневартовск', 'СК "Зал международных встреч"', 'Березин Алексей Германович', '1987'),
	('Газпром-Югра', 'Сургут', 'СК "Премьер-Арена"', 'Важенин Юрий Иванович', '1996'),
	('Оренбуржье', 'Оренбург', 'СК "Олимпийский"', 'Иванов Олег Николаевич', '1983'),
	('Енисей', 'Красноярск', 'ДС имени И.Ярыгина', 'Маслов Алексей Николаевич', '1993'),
	('АСК', 'Нижний Новгород', 'ДС "Заречье"', 'Фомин Дмитрий Александрович', '2016');


INSERT INTO competitions (name, description) VALUES
	('Чемпионат России Суперлиги среди мужчин', 'Чемпионат проводится в два этапа: предварительный в сроки сентябрь-февраль, финальный - март-апрель. Преварительный этап разбивается на 28 туров, в которых 14 команд Суперлиги встречаются друг с другом в два круга(одна домашняя, одна гостевая игра). По итогам предварительного этапа составляется таблица первенства и первые 8 команд выходят в финальный этап, который проводится по олимпийской системе. В плэйоффе каждая встреча команд проходит до двух побед, финал - до трех. 6 команд, которые не прошли в финальнный этап, играют плэйаут до трех побед.'),
	('Чемпионат России молодежной лиги', NULL);

INSERT INTO teams (name, club_id, head_coach) VALUES
	('Зенит (Казань)', 1, 'Алекно Владимир Романович'),
	('Зенит (Санкт-Петербург)', 2, 'Саммелвуо Туомас'),
	('Динамо (Москва)', 3, 'Брянский Константин Влалиславович'),
	('Локомотив (Новосибирск)', 4, 'Константинов Пламен'),
	('Белогорье (Белгород)', 5, 'Пинейро Миранда Маркос'),
	('Кузбасс (Кемерово)', 6, 'Юричич Игорь'),
	('Динамо-ЛО (Сосновый Бор)', 7, 'Василенко Ярослав Алексеевич'),
	('Факел (Новый Уренгой)', 8, 'Николаев Михаил Игоревич'),
	('Урал (Уфа)', 9, 'Шулепов Игорь Юрьевич'),
	('Югра-Самотлор (Нижневартовск)', 10, 'Пясковский Валерий Владимирович'),
	('Газпром-Югра (Сургут)', 11, 'Хабибуллин Рафаэль Талгатович'),
	('Нефтяник (Оренбург)', 12, 'Викулов Владимир Владимирович'),
	('Енисей (Красноярск)', 13, 'Маринин Юрий Львович'),
	('АСК (Нижний Новгород)', 14, 'Филиппов Юрий Иванович'),
	('Зенит-УОР (Казань)', 1, 'Пономарев Владимир'),
	('Зенит-2 (Санкт-Петербург)', 2, 'Образцова Татьяна Васильевна'),
	('Динамо-Олимп (Москва)', 3, 'Сенин Эдуард Витальевич'),
	('Локомотив-2 (Новосибирск)', 4, 'Петров Георгий Иванович'),
	('Белогорье-2 (Белгород)', 5, 'Брусенцев Сергей Алексеевич'),
	('Кузбасс-молодежка (Кемерово)', 6, 'Матусевич Денис');

/* Подаем заявки на участие команд в Чемпионате России в сезоне 2021-2022.
 */
INSERT INTO team_requests (competition_id, team_id, season) VALUES
	(1, 1, 2022), (1, 2, 2022), (1, 3, 2022), (1, 4, 2022), (1, 5, 2022), (1, 6, 2022), (1, 7, 2022),
	(1, 8, 2022), (1, 9, 2022), (1, 10, 2022), (1, 11, 2022), (1, 12, 2022), (1, 13, 2022), (1, 14, 2022),
	(2, 15, 2022), (2, 16, 2022), (2, 17, 2022), (2, 18, 2022), (2, 19, 2022), (2, 20, 2022);

DROP PROCEDURE IF EXISTS adding_player;
/* Данная процедура с помощью транзакций добавляет записи об игроках одновременно в таблицы players и profiles,
   чтобы у каждого игрока, добаленного в players, существовала запись и в profiles.
 */
DELIMITER //
CREATE PROCEDURE adding_player(
	firstname VARCHAR(100), lastname VARCHAR(100), main_role VARCHAR(30), playing_number INT, club_id INT,
	gender BIT, birthday DATE, birthplace VARCHAR(100), height INT, career TEXT, achievements TEXT
	)
BEGIN
	DECLARE `_rollback` BIT DEFAULT 0;
	DECLARE code VARCHAR(100);
	DECLARE error_text VARCHAR(100);
	DECLARE trans_result VARCHAR(200) DEFAULT 'Adding a player was successful';
	
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
	BEGIN
		SET `_rollback` = 1;
		GET STACKED DIAGNOSTICS CONDITION 1
			code = RETURNED_SQLSTATE, error_text = MESSAGE_TEXT;
		SET trans_result = CONCAT('Adding player error occured. Code: ', code, '. Text: ', error_text);
	END;

	START TRANSACTION;
		INSERT INTO players (firstname, lastname, main_role, playing_number, club_id)
		VALUES (firstname, lastname, main_role, playing_number, club_id);
		
		INSERT INTO profiles (player_id, gender, birthday, birthplace, height, career, achievements)
		VALUES (LAST_INSERT_ID(), gender, birthday, birthplace, height, career, achievements);
	IF `_rollback` = 1 THEN
		ROLLBACK;
		SELECT trans_result;
	ELSE
		COMMIT;
	END IF;
END//
DELIMITER ;

/* Далее добавляем актуальную информацию об игроках и указываем составы команд к заявке на предстоящий сезон.
 */
CALL adding_player('Максим', 'Михайлов', 'opposite hitter', 18, 1, 1, '1988-03-19', 'Ленинградская обл', 202, '2003-2005 - Строитель (Ярославль), 2005-2008 - Нефтяник (Ярославль), 2008-2010 - Ярославич (Ярославль), с 2010 года - Зенит (Казань)', 'Звание: заслуженный мастер спорта. Олимпийский чемпион, чемпион Европы, победитель Лиги Наций, победитель Клубного чемпионата мира, победитель Лиги чемпионов, чемпион России');
CALL adding_player('Александр', 'Бутько', 'setter', 12, 1, 1, '1986-03-18', 'Гродно, Беларусь', 198, 'С 2016 - Зенит (Казань)', 'Звание: ЗМС');
CALL adding_player('Артем', 'Вольвич', 'middle blocker', 4, 1, 1, '1990-01-22', 'Нижневартовск', 213, 'С 2016 - Зенит (Казань)', 'Звание: МСМК');
CALL adding_player('Александр', 'Волков', 'middle blocker', 7, 1, 1, '1985-02-14', 'Москва', 210, 'С 2011 - Зенит (Казань)', 'Звание: ЗМС');
CALL adding_player('Эрвин', 'Нгапет', 'outside hitter', 9, 1, 1, '1991-02-12', 'Сен-Рафаэль, Франция', 194, 'С 2018 - Зенит (Казань)', 'Звание: -');
CALL adding_player('Федор', 'Воронков', 'outside hitter', 2, 1, 1, '1995-12-10', 'Новоалтайск', 207, 'С 2019 - Зенит (Казань)', 'Звание: КМС');
CALL adding_player('Валентин', 'Голубев', 'libero', 17, 1, 1, '1992-05-03', 'Хабаровский край', 190, 'С 2019 - Зенит (Казань)', 'Звание: МСМК');
CALL adding_player('Дмитрий', 'Ковалев', 'setter', 3, 2, 1, '1991-03-15', 'Пермь', 198, 'С 2019 - Зенит (Санкт-Петербург)', 'Звание: МСМК');
CALL adding_player('Виктор', 'Полетаев', 'opposite hitter', 17, 2, 1, '1995-07-27', 'Казань', 196, 'С 2020 - Зенит (Санкт-Петербург)', 'Звание: МСМК');
CALL adding_player('Игорь', 'Филиппов', 'middle blocker', 11, 2, 1, '1991-03-19', 'Ярославль', 205, 'С 2019 - Зенит (Санкт-Петербург)', 'Звание: МСМК');
CALL adding_player('Иван', 'Яковлев', 'middle blocker', 9, 2, 1, '1995-04-17', 'Москва', 207, 'С 2019 - Зенит (Санкт-Петербург)', 'Звание: МС');
CALL adding_player('Ореол', 'Камехо', 'outside hitter', 15, 2, 1, '1986-07-22', 'Куба', 207, 'С 2017 - Зенит (Санкт-Петербург)', 'Звание: -');
CALL adding_player('Егор', 'Клюка', 'outside hitter', 18, 2, 1, '1995-06-15', 'Беларусь', 207, 'С 2020 - Зенит (Санкт-Петербург)', 'Звание: МСМК');
CALL adding_player('Евгений', 'Андреев', 'libero', 12, 2, 1, '1995-01-06', 'Тюмень', 176, 'С 2019 - Зенит (Санкт-Петербург)', 'Звание: МС');
CALL adding_player('Павел', 'Панков', 'setter', 11, 3, 1, '1995-08-14', 'Москва', 198, 'С 2019 - Динамо (Москва)', 'Звание: МСМК');
CALL adding_player('Цветан', 'Соколов', 'opposite hitter', 19, 3, 1, '1989-12-31', 'Дупница, Болгария', 206, 'С 2020 - Динамо (Москва)', 'Звание: -');
CALL adding_player('Илья', 'Власов', 'middle blocker', 2, 3, 1, '1995-08-03', 'Кумертае, Башкортостан', 210, 'С 2018 - Динамо (Москва)', 'Звание: МСМК');
CALL adding_player('Вадим', 'Лихошерстов', 'middle blocker', 24, 3, 1, '1989-01-23', 'Харьков, Украина', 218, 'С 2020 - Динамо (Москва)', 'Звание: МС');
CALL adding_player('Ярослав', 'Подлесных', 'outside hitter', 1, 3, 1, '1994-09-03', 'Пятигорск', 199, 'С 2020 - Динамо (Москва)', 'Звание: МС');
CALL adding_player('Антон', 'Семышев', 'outside hitter', 18, 3, 1, '1997-08-22', 'Подольск', 204, 'С 2020 - Динамо (Москва)', 'Звание: МС');
CALL adding_player('Евгений', 'Баранов', 'libero', 7, 3, 1, '1995-06-30', 'Архангельск', 182, 'С 2015 - Динамо (Москва)', 'Звание: МС');
CALL adding_player('Константин', 'Абаев', 'setter', 7, 4, 1, '1999-06-17', 'Новосибирск', 198, 'С 2019 - Локомотив (Новосибириск)', 'Звание: МС');
CALL adding_player('Павел', 'Круглов', 'opposite hitter', 15, 4, 1, '1985-09-17', 'Москва', 204, 'С 2019 - Локомотив (Новосибириск)', 'Звание: МСМК');
CALL adding_player('Ильяс', 'Куркаев', 'middle blocker', 20, 4, 1, '1994-01-18', 'Новосибирск', 208, 'С 2016 - Локомотив (Новосибириск)', 'Звание: МСМК');
CALL adding_player('Александр', 'Ткачев', 'middle blocker', 13, 4, 1, '1991-04-18', 'Новосибирск', 201, 'С 2017 - Локомотив (Новосибириск)', 'Звание: МС');
CALL adding_player('Сергей', 'Савин', 'outside hitter', 8, 4, 1, '1988-10-07', 'Ханты-Мансийск', 201, 'С 2015 - Локомотив (Новосибириск)', 'Звание: МСМК');
CALL adding_player('Илья', 'Казаченков', 'outside hitter', 19, 4, 1, '2001-01-30', 'Москва', 209, 'С 2020 - Локомотив (Новосибириск)', 'Звание: КМС');
CALL adding_player('Роман', 'Мартынюк', 'libero', 1, 4, 1, '1987-04-13', 'Пермь', 182, 'С 2017 - Локомотив (Новосибириск)', 'Звание: МСМК');
CALL adding_player('Сергей', 'Багрей', 'setter', 16, 5, 1, '1987-08-14', 'Белгород', 192, 'С 2019 - Белогорье (Белгород)', 'Звание: МС');
CALL adding_player('Егор', 'Сиденко', 'opposite hitter', 18, 5, 1, '1999-09-07', 'Белгород', 199, 'С 2018 - Белогорье (Белгород)', 'Звание: -');
CALL adding_player('Алексей', 'Самойленко', 'middle blocker', 13, 5, 1, '1985-06-23', 'Ростов', 207, 'С 2020 - Белогорье (Белгород)', 'Звание: МС');
CALL adding_player('Сергей', 'Червяков', 'middle blocker', 17, 5, 1, '1989-09-17', 'Санкт-Петербург', 202, 'С 2019 - Белогорье (Белгород)', 'Звание: МС');
CALL adding_player('Дмитрий', 'Ильиных', 'outside hitter', 15, 5, 1, '1987-01-31', 'Адлер', 202, 'С 2020 - Белогорье (Белгород)', 'Звание: ЗМС');
CALL adding_player('Иван', 'Кузнецов', 'outside hitter', 14, 5, 1, '1999-11-13', 'Белгород', 204, 'С 2019 - Белогорье (Белгород)', 'Звание: КМС');
CALL adding_player('Никита', 'Еремин', 'libero', 12, 5, 1, '1990-09-01', 'Белгород', 182, 'С 2020 - Белогорье (Белгород)', 'Звание: МС');
CALL adding_player('Егор', 'Кречетов', 'setter', 11, 6, 1, '1999-01-01', NULL, 189, 'С 2021 - Кузбасс (Кемерово)', 'Звание: -');
CALL adding_player('Виталий', 'Папазов', 'opposite hitter', NULL, 6, 1, '1992-04-06', 'Белгород', 203, 'С 2021 - Кузбасс (Кемерово)', 'Звание: КМС');
CALL adding_player('Петар', 'Крсманович', 'middle blocker', 7, 6, 1, '1990-06-01', 'Сербия', 205, 'С 2020 - Кузбасс (Кемерово)', 'Звание: -');
CALL adding_player('Инал', 'Тавасиев', 'middle blocker', 15, 6, 1, '1989-03-28', NULL, 202, 'С 2014 - Кузбасс (Кемерово)', 'Звание: КМС');
CALL adding_player('Евгений', 'Сивожелез', 'outside hitter', 6, 6, 1, '1986-08-06', 'Нижневартовск', 196, 'С 2019 - Кузбасс (Кемерово)', 'Звание: МСМК');
CALL adding_player('Антон', 'Карпухов', 'outside hitter', 3, 6, 1, '1988-04-23', 'Смоленск', 197, 'С 2015 - Кузбасс (Кемерово)', 'Звание: КМС');
CALL adding_player('Алексей', 'Обмочаев', 'libero', 1, 6, 1, '1989-05-22', NULL, 190, 'С 2020 - Кузбасс (Кемерово)', 'Звание: ЗМС');
CALL adding_player('Марат', 'Гафаров', 'setter', 7, 7, 1, '1994-10-10', NULL, 194, 'С 2020 - Динамо-ЛО (Сосновый Бор)', 'Звание: -');
CALL adding_player('Андрей', 'Колесник', 'opposite hitter', 5, 7, 1, '1991-06-23', 'Ярославль', 200, 'С 2018 - Динамо-ЛО (Сосновый Бор)', 'Звание: МСМК');
CALL adding_player('Александр', 'Абросимов', 'middle blocker', 25, 7, 1, '1983-08-25', NULL, 207, 'С 2020 - Динамо-ЛО (Сосновый Бор)', 'Звание: МС');
CALL adding_player('Сергей', 'Бусел', 'middle blocker', 15, 7, 1, '1989-05-30', 'Беларусь', 207, 'С 2020 - Динамо-ЛО (Сосновый Бор)', 'Звание: -');
CALL adding_player('Денис', 'Бирюков', 'outside hitter', 8, 7, 1, '198-12-08', NULL, 204, 'С 2020 - Динамо-ЛО (Сосновый Бор)', 'Звание: МСМК');
CALL adding_player('Лукаш', 'Дивиш', 'outside hitter', 2, 7, 1, '1986-02-20', 'Чехия', 201, 'С 2020 - Динамо-ЛО (Сосновый Бор)', 'Звание: МС');
CALL adding_player('Дмитрий', 'Кириченко', 'libero', 18, 7, 1, '1987-06-16', NULL, 188, 'С 2020 - Динамо-ЛО (Сосновый Бор)', 'Звание: МС');
CALL adding_player('Тимофей', 'Жуковский', 'setter', 1, 8, 1, '1989-10-13', 'Минск, Беларусь', 197, 'С 2020 - Факел (Новый Уренгой)', 'Звание: -');
CALL adding_player('Маским', 'Жигалов', 'opposite hitter', 8, 8, 1, '1989-07-26', 'пос.Степной, Казахстан', 203, 'С 2020 - Факел (Новый Уренгой)', 'Звание: МСМК');
CALL adding_player('Александр', 'Гуцалюк', 'middle blocker', 3, 8, 1, '1988-01-15', 'Мостовской', 205, 'С 2020 - Факел (Новый Уренгой)', 'Звание: МС');
CALL adding_player('Виталий', 'Дикарев', 'middle blocker', 2, 8, 1, '1999-11-13', 'Херсон, Украина', 208, 'С 2020 - Факел (Новый Уренгой)', 'Звание: КМС');
CALL adding_player('Дмитрий', 'Волков', 'outside hitter', 15, 8, 1, '1995-05-25', 'Новокуйбышевск', 202, 'С 2011 - Факел (Новый Уренгой)', 'Звание: МСМК');
CALL adding_player('Денис', 'Богдан', 'outside hitter', 10, 8, 1, '1996-10-13', 'Гродно, Беларусь', 200, 'С 2015 - Факел (Новый Уренгой)', 'Звание: МСМК');
CALL adding_player('Эрик', 'Шоджи', 'libero', 22, 8, 1, '1989-08-24', 'Гонолулу, Гавайи', 184, 'С 2018 - Факел (Новый Уренгой)', 'Звание: -');
CALL adding_player('Ярослав', 'Остраховский', 'setter', 1, 9, 1, '1991-05-11', 'Уфа', 198, 'С 2021 - Урал (Уфа)', 'Звание: -');
CALL adding_player('Евгений', 'Рыбаков', 'opposite hitter', 3, 9, 1, '1995-03-03', NULL, 205, 'С 2021 - Урал (Уфа)', 'Звание: -');
CALL adding_player('Леонид', 'Кузнецов', 'middle blocker', 7, 9, 1, '1983-08-07', 'Уфа', 210, 'С 2013 - Урал (Уфа)', 'Звание: -');
CALL adding_player('Максим', 'Куликов', 'middle blocker', 23, 9, 1, '1992-03-06', NULL, 206, 'С 2021 - Урал (Уфа)', 'Звание: -');
CALL adding_player('Егор', 'Феоктистов', 'outside hitter', 17, 9, 1, '1993-06-22', 'Белорецк', 203, 'С 2013 - Урал (Уфа)', 'Звание: -');
CALL adding_player('Джон', 'Перрин', 'outside hitter', 2, 9, 1, '1989-05-17', 'Канада', 201, 'С 2021 - Урал (Уфа)', 'Звание: -');
CALL adding_player('Роман', 'Брагин', 'libero', 10, 9, 1, '1987-04-17', NULL, 187, 'С 2021 - Урал (Уфа)', 'Звание: -');
CALL adding_player('Игорь', 'Коваликов', 'setter', 1, 10, 1, '1995-02-11', 'Луганск', 195, 'С 2017 - Югра-Самотлор (Нижневартовск)', 'Звание: -');
CALL adding_player('Виталий', 'Папазов', 'opposite hitter', 10, 10, 1, '1992-04-06', 'Мелитополь Украина', 204, 'С 2019 - Югра-Самотлор (Нижневартовск)', 'Звание: -');
CALL adding_player('Кирилл', 'Пиун', 'middle blocker', 4, 10, 1, '1989-05-10', 'Мелитополь Украина', 212, 'С 2020 - Югра-Самотлор (Нижневартовск)', 'Звание: -');
CALL adding_player('Юрий', 'Цепков', 'middle blocker', 3, 10, 1, '1995-09-21', 'Донецк, Украина', 200, 'С 2015 - Югра-Самотлор (Нижневартовск)', 'Звание: -');
CALL adding_player('Дмитрий', 'Макаренко', 'outside hitter', 8, 10, 1, '1985-01-01', NULL, 200, 'С 2021 - Югра-Самотлор (Нижневартовск)', 'Звание: МС');
CALL adding_player('Никита', 'Поломошин', 'outside hitter', 11, 10, 1, '1999-12-10', 'Сургут', 195, 'С 2014 - Югра-Самотлор (Нижневартовск)', 'Звание: -');
CALL adding_player('Никита', 'Вишневецкий', 'libero', 16, 10, 1, '1995-02-03', 'Краснодар', 184, 'С 2019 - Югра-Самотлор (Нижневартовск)', 'Звание: -');
CALL adding_player('Евгений', 'Рукавишников', 'setter', 12, 11, 1, '1991-06-03', NULL, 200, 'С 2021 - Газпром-Югра (Сургут)', 'Звание: -');
CALL adding_player('Раджаб', 'Шахбанмирзаев', 'opposite hitter', 16, 11, 1, '1998-03-20', NULL, 198, 'С 2021 - Газпром-Югра (Сургут)', 'Звание: -');
CALL adding_player('Артем', 'Довгань', 'middle blocker', 15, 11, 1, '1989-07-15', NULL, 204, 'С 2021 - Газпром-Югра (Сургут)', 'Звание: -');
CALL adding_player('Егор', 'Якутин', 'middle blocker', 4, 11, 1, '1997-01-27', NULL, 207, 'С 2021 - Газпром-Югра (Сургут)', 'Звание: -');
CALL adding_player('Кирилл', 'Костыленко', 'outside hitter', 11, 11, 1, '1992-03-08', NULL, 200, 'С 2021 - Газпром-Югра (Сургут)', 'Звание: -');
CALL adding_player('Александр', 'Слободянюк', 'outside hitter', 21, 11, 1, '2000-01-30', NULL, 197, 'С 2021 - Газпром-Югра (Сургут)', 'Звание: -');
CALL adding_player('Александр', 'Олейников', 'libero', 5, 11, 1, '2003-11-24', NULL, 186, 'С 2021 - Газпром-Югра (Сургут)', 'Звание: -');
CALL adding_player('Роман', 'Егоров', 'setter', 1, 12, 1, '1986-02-11', NULL, 188, 'С 2021 - Нефтяник (Оренбург)', 'Звание: -');
CALL adding_player('Павел', 'Мороз', 'opposite hitter', 8, 12, 1, '1987-02-26', NULL, 205, 'С 2021 - Нефтяник (Оренбург)', 'Звание: -');
CALL adding_player('Андрей', 'Ананьев', 'middle blocker', 5, 12, 1, '1992-06-21', NULL, 205, 'С 2021 - Нефтяник (Оренбург)', 'Звание: МС');
CALL adding_player('Иван', 'Козицын', 'middle blocker', 11, 12, 1, '1987-03-20', NULL, 203, 'С 2021 - Нефтяник (Оренбург)', 'Звание: МС');
CALL adding_player('Леонид', 'Щадилов', 'outside hitter', 9, 12, 1, '1991-08-14', NULL, 205, 'С 2021 - Нефтяник (Оренбург)', 'Звание: МСМК');
CALL adding_player('Сергей', 'Панов', 'outside hitter', 17, 12, 1, '1993-02-02', NULL, 196, 'С 2021 - Нефтяник (Оренбург)', 'Звание: -');
CALL adding_player('Максим', 'Максименко', 'libero', 14, 12, 1, '1994-11-13', NULL, 189, 'С 2021 - Нефтяник (Оренбург)', 'Звание: МСМК');
CALL adding_player('Роман', 'Жось', 'setter', 17, 13, 1, '1995-01-04', NULL, 197, 'С 2021 - Енисей (Красноярск)', 'Звание: МС');
CALL adding_player('Кирилл', 'Клец', 'opposite hitter', 13, 13, 1, '1998-03-15', NULL, 210, 'С 2021 - Енисей (Красноярск)', 'Звание: МС');
CALL adding_player('Александр', 'Крицкий', 'middle blocker', 9, 13, 1, '1985-07-02', NULL, 202, 'С 2021 - Енисей (Красноярск)', 'Звание: МС');
CALL adding_player('Дмитрий', 'Жук', 'middle blocker', 11, 13, 1, '1993-11-12', NULL, 213, 'С 2021 - Енисей (Красноярск)', 'Звание: КМС');
CALL adding_player('Никита', 'Ааксютин', 'outside hitter', 10, 13, 1, '1994-03-27', NULL, 200, 'С 2021 - Енисей (Красноярск)', 'Звание: КМС');
CALL adding_player('Иван', 'Пискарев', 'outside hitter', 2, 13, 1, '1997-06-07', NULL, 197, 'С 2021 - Енисей (Красноярск)', 'Звание: КМС');
CALL adding_player('Александр', 'Янутов', 'libero', 12, 13, 1, '1983-06-19', NULL, 195, 'С 2021 - Енисей (Красноярск)', 'Звание: МСМК');
CALL adding_player('Денисс', 'Петровс', 'setter', 11, 14, 1, '1986-08-31', 'Даугавпилс, Латвия', 189, 'С 2019 - АСК (Нижний Новгород)', 'Звание: -');
CALL adding_player('Виталий', 'Фетцов', 'opposite hitter', 10, 14, 1, '1995-01-24', 'Усть-Кут', 200, 'С 2020 - АСК (Нижний Новгород)', 'Звание: -');
CALL adding_player('Виктор', 'Никоненко', 'middle blocker', 8, 14, 1, '1980-09-21', 'Смоленск', 197, 'С 2018 - АСК (Нижний Новгород)', 'Звание: КМС');
CALL adding_player('Антон', 'Андреев', 'middle blocker', 5, 14, 1, '1987-07-23', 'Казань', 203, 'С 2018 - АСК (Нижний Новгород)', 'Звание: -');
CALL adding_player('Андрей', 'Титич', 'outside hitter', 3, 14, 1, '1986-03-10', 'Ростов Великий', 201, 'С 2020 - АСК (Нижний Новгород)', 'Звание: -');
CALL adding_player('Иван', 'Валеев', 'outside hitter', 13, 14, 1, '1991-02-03', 'Зеленогорск', 200, 'С 2017 - АСК (Нижний Новгород)', 'Звание: -');
CALL adding_player('Артем', 'Крайнов', 'libero', 2, 14, 1, '2002-02-12', 'Нижний Новогород', 183, 'С 2018 - АСК (Нижний Новгород)', 'Звание: -');

INSERT INTO team_lineups (request_id, player_id) VALUES
	(1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7),
	(2, 8), (2, 9), (2, 10), (2, 11), (2, 12), (2, 13), (2, 14),
	(3, 15), (3, 16), (3, 17), (3, 18), (3, 19), (3, 20), (3, 21),
	(4, 22), (4, 23), (4, 24), (4, 25), (4, 26), (4, 27), (4, 28),
	(5, 29), (5, 30), (5, 31), (5, 32), (5, 33), (5, 34), (5, 35),
	(6, 36), (6, 37), (6, 38), (6, 39), (6, 40), (6, 41), (6, 42),
	(7, 43), (7, 44), (7, 45), (7, 46), (7, 47), (7, 48), (7, 49),
	(8, 50), (8, 51), (8, 52), (8, 53), (8, 54), (8, 55), (8, 56),
	(9, 57), (9, 58), (9, 59), (9, 60), (9, 61), (9, 62), (9, 63),
	(10, 64), (10, 65), (10, 66), (10, 67), (10, 68), (10, 69), (10, 70),
	(11, 71), (11, 72), (11, 73), (11, 74), (11, 75), (11, 76), (11, 77),
	(12, 78), (12, 79), (12, 80), (12, 81), (12, 82), (12, 83), (12, 84),
	(13, 85), (13, 86), (13, 87), (13, 88), (13, 89), (13, 90), (13, 91),
	(14, 92), (14, 93), (14, 94), (14, 95), (14, 96), (14, 97), (14, 98);



DROP PROCEDURE IF EXISTS prelim_stg_teams_mix;
/* По схеме чемпионата предварительный этап проводится в 26 туров(26 уикендов) в два круга(дома и в гостях). В каждом уикенде 7 игр, в которых должны принять участие
   все команды(14) по одному разу. Итого получается 182 игры (декартово произведение команд, исключая встречи с самими собой).
   Эту задачу по перетасовке команд решил с помощью следующей процедуры. Правда во второй половине этапа всё же встречаются команды,
   проводящие несколько игр за один уикенд. На практике, как это обычно бывает, это решается переносом встреч.
 */
DELIMITER //
CREATE PROCEDURE prelim_stg_teams_mix(teams_amount INT, season YEAR)
BEGIN
	DECLARE tours_amount, games_in_tour, cur_tour INT;
	DECLARE start_season_date DATE;

	DROP TABLE IF EXISTS tmp_games;
	/* Создадим таблицу по декартову произведению команд, исключающую встречи с самими собой.*/
	CREATE TABLE tmp_games
		SELECT fst.t1 home_team, snd.t2 guest_team FROM
			((SELECT 1 t1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION 
			SELECT 8 UNION SELECT 9 UNION SELECT 10 UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14) LIMIT 14) fst,
			((SELECT 1 t2 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION 
			SELECT 8 UNION SELECT 9 UNION SELECT 10 UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14) LIMIT 14) snd
			WHERE fst.t1 != snd.t2
			ORDER BY RAND();
	
	/* Выберем начало сезона(начало первых игр) как первая пятница сентября.*/
	SET start_season_date = CONCAT((season - 1), '-09-01');
	WHILE DAYOFWEEK(start_season_date) != 6 DO
		SET start_season_date = start_season_date + INTERVAL 1 DAY;
	END WHILE;
	
	SET tours_amount = (teams_amount - 1) * 2;
	SET games_in_tour = teams_amount / 2;
	SET cur_tour = 1;
	
	/*Далее во внешнем цикле каждую итерацию(всего 26) обьявляем курсор для таблицы декартова произведения и создаем таблицу
	  для текущего тура. Во внутреннем цикле собственно наполняем текущий тур играми, так чтобы команды встречались в нем только один раз,
	  и удаляем из комбинацию из данных команд и декартова произведения.*/
	ext_cycle: WHILE cur_tour <= tours_amount DO
		int_block: BEGIN
			DECLARE i, h, g INT DEFAULT 0;
			DECLARE is_end INT DEFAULT FALSE;
			DECLARE cur_game CURSOR FOR SELECT home_team, guest_team FROM tmp_games;
			DECLARE CONTINUE HANDLER FOR NOT FOUND
				SET is_end = TRUE;
		
			DROP TABLE IF EXISTS tmp_tour;
			CREATE TABLE tmp_tour (
				game_date DATE,
				home_team_id INT UNSIGNED,
				guest_team_id INT UNSIGNED,
				competition_id SMALLINT UNSIGNED,
				competition_stage VARCHAR(255),
				game_place VARCHAR(255)
			);
			
			OPEN cur_game;
			
			int_cycle: WHILE i < games_in_tour DO
				FETCH cur_game INTO h, g;
			
				IF is_end THEN
					full_add_cycle: REPEAT
						/* В случае, когда курсор подошел к концу таблицы, а 7 игр в туре не набраны, данным циклом просто
						   добираем игры в тур из конца таблицы декартова произведения*/
						SELECT home_team, guest_team INTO h, g
							FROM tmp_games ORDER BY home_team DESC, guest_team LIMIT 1;
						
						INSERT INTO tmp_tour
							SET
								game_date = (start_season_date + INTERVAL FLOOR(RAND()*3) DAY) + INTERVAL (cur_tour - 1) WEEK,
								home_team_id = h,
								guest_team_id = g,
								competition_id = 1,
								competition_stage = CONCAT('preliminary stage, tour ', cur_tour),
								game_place = (SELECT CONCAT(arena_name, ' (', hometown, ')') FROM clubs 
									WHERE id = (SELECT club_id FROM teams WHERE id = h));
								
						DELETE FROM tmp_games WHERE (home_team = h AND guest_team = g);
					
						SELECT COUNT(home_team_id) INTO i FROM tmp_tour;
					UNTIL i >= games_in_tour
					END REPEAT full_add_cycle;
				
					LEAVE int_cycle;
				END IF;
			
				IF ((h NOT IN (SELECT home_team_id FROM tmp_tour)) AND (h NOT IN (SELECT guest_team_id FROM tmp_tour))
				AND (g NOT IN (SELECT home_team_id FROM tmp_tour)) AND (g NOT IN (SELECT guest_team_id FROM tmp_tour))) THEN
					INSERT INTO tmp_tour
						SET
							game_date = (start_season_date + INTERVAL FLOOR(RAND()*3) DAY) + INTERVAL (cur_tour - 1) WEEK,
							home_team_id = h,
							guest_team_id = g,
							competition_id = 1,
							competition_stage = CONCAT('preliminary stage, tour ', cur_tour),
							game_place = (SELECT CONCAT(arena_name, ' (', hometown, ')') FROM clubs 
								WHERE id = (SELECT club_id FROM teams WHERE id = h));
					DELETE FROM tmp_games WHERE (home_team = h AND guest_team = g);
					SET i = i + 1;
				END IF;
			END WHILE int_cycle;
			
			CLOSE cur_game;
			
			INSERT INTO games_schedule
				SELECT * FROM tmp_tour ORDER BY game_date;
			SET cur_tour = cur_tour + 1;
		END int_block;
	END WHILE ext_cycle;
	
	DROP TABLE tmp_tour;
	DROP TABLE tmp_games;
END//
DELIMITER ;

/* Перетасовываем 14 команд для предварительного этапа*/
CALL prelim_stg_teams_mix(14, 2022);

/*
Для удобочитаемости создадим представление расписания игр. 
*/
CREATE OR REPLACE VIEW schedule_viewer AS
	SELECT
		gs.game_date,
		t1.name home_team,
		t2.name guest_team,
		c.name competition,
		gs.competition_stage,
		gs.game_place
	FROM games_schedule gs
	JOIN teams t1 ON gs.home_team_id = t1.id
	JOIN teams t2 ON gs.guest_team_id = t2.id
	JOIN competitions c ON gs.competition_id = c.id
	ORDER BY gs.game_date;

/* Следующими запросом можно просмотреть расписание игр на определенный тур этапа.
SET @tour_number = 12;
SELECT 
	gs.game_date,
	t1.name home_team,
	t2.name guest_team,
	@tour_number tour,
	gs.game_place
	FROM games_schedule gs
	JOIN teams t1 ON gs.home_team_id = t1.id
	JOIN teams t2 ON gs.guest_team_id = t2.id
	WHERE gs.competition_stage LIKE CONCAT('preliminary stage, tour ', @tour_number)
	ORDER BY gs.game_date;
*/

DROP PROCEDURE IF EXISTS assign_rand_results;
/*Создадим процедуру, которая читает расписание с определнной даты, проставляет случайные результаты и заносит в соответствующую таблицу.*/
DELIMITER //
CREATE PROCEDURE assign_rand_results(start_date DATE)
BEGIN
	DECLARE g_d DATE;
	DECLARE ht_id, gt_id, comp_id, rand_num INT;
	DECLARE comp_stg VARCHAR(255);
	DECLARE scr CHAR(3);
	DECLARE is_end INT DEFAULT FALSE;
	DECLARE cur_schedule CURSOR FOR
		SELECT game_date, home_team_id, guest_team_id, competition_id, competition_stage
		FROM games_schedule WHERE game_date >= start_date;
	DECLARE CONTINUE HANDLER FOR NOT FOUND
		SET is_end = TRUE;
	
	OPEN cur_schedule;

	cur_cycle: LOOP
		FETCH cur_schedule INTO g_d, ht_id, gt_id, comp_id, comp_stg;
		IF is_end THEN LEAVE cur_cycle;
		END IF;
		
		SET rand_num = FLOOR(RAND() * 6);
		SET scr = (CASE rand_num
			WHEN 0 THEN '3:0'
			WHEN 1 THEN '3:1'
			WHEN 2 THEN '3:2'
			WHEN 3 THEN '2:3'
			WHEN 4 THEN '1:3'
			ELSE '0:3' END);
		
		INSERT INTO games_results
			SET
				game_date = g_d,
				home_team_id = ht_id,
				guest_team_id = gt_id,
				competition_id = comp_id,
				competition_stage = comp_stg,
				score = scr;
		
	END LOOP cur_cycle;
	
	CLOSE cur_schedule;
END//
DELIMITER ;

CALL assign_rand_results('2021-09-01');

/* Также для удобочитаемости создадим представление результатов.
*/
CREATE OR REPLACE VIEW results_viewer AS
	SELECT
		gr.game_date,
		t1.name home_team,
		t2.name guest_team,
		c.name competition,
		gr.competition_stage,
		gr.score
	FROM games_results gr
	JOIN teams t1 ON gr.home_team_id = t1.id
	JOIN teams t2 ON gr.guest_team_id = t2.id
	JOIN competitions c ON gr.competition_id = c.id
	ORDER BY gr.game_date;

/* Этим запросом можно просмотреть результаты игр на определенный тур этапа.
SET @tour_number = 12;
SELECT 
	gr.game_date,
	t1.name home_team,
	t2.name guest_team,
	@tour_number tour,
	gr.score
	FROM games_results gr
	JOIN teams t1 ON gr.home_team_id = t1.id
	JOIN teams t2 ON gr.guest_team_id = t2.id
	WHERE gr.competition_stage LIKE CONCAT('preliminary stage, tour ', @tour_number)
	ORDER BY gr.game_date;
*/

/* По окончании предварительного этапа по результам проведенных игр создается сводная таблица первенства,
   на основании которой далее в финальный проходят первые 8 команд. Следующее представление отражает данную сводную таблицу.
*/
CREATE OR REPLACE VIEW summary_prelim_stg_table AS
SELECT
	tot_lst.team team_id,
	ts.name,
	COUNT(tot_lst.team) total_games,
	SUM(IF(tot_lst.score LIKE '3%', 1, 0)) won_games,
	SUM(IF(tot_lst.score NOT LIKE '3%', 1, 0)) lost_games,
	SUM(CASE tot_lst.score WHEN '3:0' THEN 3 WHEN '3:1' THEN 3
				   WHEN '3:2' THEN 2 WHEN '2:3' THEN 1
				   ELSE 0 END) spec_scores,
	SUM(CASE WHEN tot_lst.score LIKE '3%' THEN 3
			 WHEN tot_lst.score LIKE '2%' THEN 2
			 WHEN tot_lst.score LIKE '1%' THEN 1
			 ELSE 0 END) won_sets,
	SUM(CASE WHEN tot_lst.score LIKE '%3' THEN 3
			 WHEN tot_lst.score LIKE '%2' THEN 2
			 WHEN tot_lst.score LIKE '%1' THEN 1
			 ELSE 0 END) lost_sets
	# GROUP_CONCAT(score ORDER BY score DESC SEPARATOR ', ') games_scores
FROM (
	SELECT home_team_id team, score FROM games_results
		WHERE (competition_id = 1 AND competition_stage LIKE 'preliminary stage%')
	UNION ALL
	SELECT
		guest_team_id team,
		(CASE score WHEN '3:0' THEN '0:3' WHEN '3:1' THEN '1:3'
					WHEN '3:2' THEN '2:3' WHEN '2:3' THEN '3:2'
					WHEN '1:3' THEN '3:1' ELSE '3:0' END) score
		FROM games_results
		WHERE (competition_id = 1 AND competition_stage LIKE 'preliminary stage%')
) tot_lst JOIN teams ts ON tot_lst.team = ts.id
GROUP BY team
ORDER BY won_games DESC, spec_scores DESC, won_sets DESC, lost_games;



DROP PROCEDURE IF EXISTS final_stg_team_mix;
/* Эта процедура тасует команды на следующий финальный этап, исходя из результатов предыдущего, на основе представления.
*/
DELIMITER //
CREATE PROCEDURE final_stg_team_mix (view_name VARCHAR(255), teams_amount INT, season YEAR)
BEGIN
	DECLARE start_final_stg_date DATE;
	DECLARE i INT DEFAULT 0;

	SET start_final_stg_date = CONCAT(season, '-03-01');
	WHILE DAYOFWEEK(start_final_stg_date) != 7 DO
		SET start_final_stg_date = start_final_stg_date + INTERVAL 1 DAY;
	END WHILE;
	
	DROP TEMPORARY TABLE IF EXISTS tmp_final;
	CREATE TEMPORARY TABLE tmp_final
		LIKE games_schedule;

	WHILE i < (teams_amount/2) DO
		SET @i = i;
		SET @query1_text = CONCAT('SELECT team_id INTO @t1 FROM summary_', view_name,'_table LIMIT ?, 1');
		PREPARE query1 FROM @query1_text;
		EXECUTE query1 USING @i;
		DROP PREPARE query1;
	
		SET @j = teams_amount - 1 - i;
		SET @query2_text = CONCAT('SELECT team_id INTO @t2 FROM summary_', view_name,'_table LIMIT ?, 1');
		PREPARE query2 FROM @query2_text;
		EXECUTE query2 USING @j;
		DROP PREPARE query2;
		
		INSERT INTO tmp_final
			SET
				game_date = start_final_stg_date + INTERVAL (CASE WHEN view_name LIKE 'prelim%' THEN 0
	 															  WHEN view_name LIKE 'quater%' THEN 3
	 															  ELSE 6 END) WEEK,
				home_team_id = @t1,
				guest_team_id = @t2,
				competition_id = 1,
				competition_stage = CONCAT('final stage, ', (CASE WHEN view_name LIKE 'prelim%' THEN 'quarter-'
	 															  WHEN view_name LIKE 'quater%' THEN 'semi-'
	 															  ELSE '' END), 'finals'),
				game_place = (SELECT CONCAT(arena_name, ' (', hometown, ')') FROM clubs 
					WHERE id = (SELECT club_id FROM teams
					WHERE id = @t1));
		
		INSERT INTO tmp_final
			SET
				game_date = start_final_stg_date + INTERVAL (CASE WHEN view_name LIKE 'prelim%' THEN 1
	 															  WHEN view_name LIKE 'quater%' THEN 4
	 															  ELSE 7 END) WEEK,
				home_team_id = @t2,
				guest_team_id = @t1,
				competition_id = 1,
				competition_stage = CONCAT('final stage, ', (CASE WHEN view_name LIKE 'prelim%' THEN 'quarter-'
	 															  WHEN view_name LIKE 'quater%' THEN 'semi-'
	 															  ELSE '' END), 'finals'),
				game_place = (SELECT CONCAT(arena_name, ' (', hometown, ')') FROM clubs 
					WHERE id = (SELECT club_id FROM teams
					WHERE id = @t2));
		
		INSERT INTO tmp_final
			SET
				game_date = start_final_stg_date + INTERVAL (CASE WHEN view_name LIKE 'prelim%' THEN 2
	 															  WHEN view_name LIKE 'quater%' THEN 5
	 															  ELSE 8 END) WEEK,
				home_team_id = @t1,
				guest_team_id = @t2,
				competition_id = 1,
				competition_stage = CONCAT('final stage, ', (CASE WHEN view_name LIKE 'prelim%' THEN 'quarter-'
	 															  WHEN view_name LIKE 'quater%' THEN 'semi-'
	 															  ELSE '' END), 'finals'),
				game_place = (SELECT CONCAT(arena_name, ' (', hometown, ')') FROM clubs 
					WHERE id = (SELECT club_id FROM teams
					WHERE id = @t1));

		SET i = i + 1;
	END WHILE;
	
	INSERT INTO games_schedule
		SELECT * FROM tmp_final ORDER BY game_date;
	
	DROP TEMPORARY TABLE tmp_final;

END//
DELIMITER ;

/* Далее вызываем процедуры, которые тасуют команды на каждый подэтап(quarter-final, semi-final, final) финального этапа,
   проставляют случайные результаты встреч. Создаем представления на каждом подэтапе.
   И так до финала.
 */
CALL final_stg_team_mix('prelim_stg', 8, 2022);

CALL assign_rand_results('2022-03-01');

		
CREATE OR REPLACE VIEW summary_quater_final_table AS
SELECT
	tot_lst.team team_id,
	ts.name,
	COUNT(tot_lst.team) total_games,
	SUM(IF(tot_lst.score LIKE '3%', 1, 0)) won_games
FROM (
	SELECT home_team_id team, score FROM games_results
		WHERE (competition_id = 1 AND competition_stage LIKE 'final stage, qu%')
	UNION ALL
	SELECT
		guest_team_id team,
		(CASE score WHEN '3:0' THEN '0:3' WHEN '3:1' THEN '1:3'
					WHEN '3:2' THEN '2:3' WHEN '2:3' THEN '3:2'
					WHEN '1:3' THEN '3:1' ELSE '3:0' END) score
		FROM games_results
		WHERE (competition_id = 1 AND competition_stage LIKE 'final stage, qu%')
) tot_lst JOIN teams ts ON tot_lst.team = ts.id
GROUP BY team
ORDER BY won_games DESC;

CALL final_stg_team_mix('quater_final', 4, 2022);

CALL assign_rand_results('2022-03-26');


CREATE OR REPLACE VIEW summary_semi_final_table AS
SELECT
	tot_lst.team team_id,
	ts.name,
	COUNT(tot_lst.team) total_games,
	SUM(IF(tot_lst.score LIKE '3%', 1, 0)) won_games
FROM (
	SELECT home_team_id team, score FROM games_results
		WHERE (competition_id = 1 AND competition_stage LIKE 'final stage, se%')
	UNION ALL
	SELECT
		guest_team_id team,
		(CASE score WHEN '3:0' THEN '0:3' WHEN '3:1' THEN '1:3'
					WHEN '3:2' THEN '2:3' WHEN '2:3' THEN '3:2'
					WHEN '1:3' THEN '3:1' ELSE '3:0' END) score
		FROM games_results
		WHERE (competition_id = 1 AND competition_stage LIKE 'final stage, se%')
) tot_lst JOIN teams ts ON tot_lst.team = ts.id
GROUP BY team
ORDER BY won_games DESC;

CALL final_stg_team_mix('semi_final', 2, 2022);

CALL assign_rand_results('2022-04-16');



/* Данный запрос выводит двух участников финала, первых из которых и является победителем Чемпионата.
*/
SELECT
	tot_lst.team team_id,
	ts.name,
	COUNT(tot_lst.team) total_games,
	SUM(IF(tot_lst.score LIKE '3%', 1, 0)) won_games
FROM (
	SELECT home_team_id team, score FROM games_results
		WHERE (competition_id = 1 AND competition_stage LIKE 'final stage, fi%')
	UNION ALL
	SELECT
		guest_team_id team,
		(CASE score WHEN '3:0' THEN '0:3' WHEN '3:1' THEN '1:3'
					WHEN '3:2' THEN '2:3' WHEN '2:3' THEN '3:2'
					WHEN '1:3' THEN '3:1' ELSE '3:0' END) score
		FROM games_results
		WHERE (competition_id = 1 AND competition_stage LIKE 'final stage, fi%')
) tot_lst JOIN teams ts ON tot_lst.team = ts.id
GROUP BY team
ORDER BY won_games DESC;
























