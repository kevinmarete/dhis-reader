/*Save cdrr*/
DROP PROCEDURE IF EXISTS proc_save_cdrr;
DELIMITER //
CREATE PROCEDURE proc_save_cdrr()
BEGIN
	DECLARE bDone INT;
	DECLARE k VARCHAR(255);
	DECLARE v VARCHAR(255);

	/*Update dhiscode to facility_id*/
	UPDATE tbl_order o INNER JOIN tbl_facility f ON f.dhiscode = o.facility SET o.facility = f.id;

	/*Format period to period_begin date type*/
	UPDATE tbl_order o SET o.period = DATE_FORMAT(STR_TO_DATE(o.period, '%Y%m') , "%Y-%m-01");

	/*Upsert cdrr from tbl_order*/
	REPLACE INTO tbl_cdrr(status, created, code, period_begin, period_end, facility_id) SELECT 'pending' status, NOW() created, 'F-CDRR' code, o.period period_begin, LAST_DAY(o.period) period_end, o.facility facility_id FROM tbl_order o INNER JOIN tbl_facility f ON f.id = o.facility GROUP BY o.facility, o.period;

	/*Update report_id to cdrr_id*/
	UPDATE tbl_order o INNER JOIN tbl_cdrr c ON c.facility_id = o.facility AND o.period = c.period_begin SET o.report_id = c.id;

	/*Upsert cdrr_log based on cdrr*/
	REPLACE INTO tbl_cdrr_log(description, created, user_id, cdrr_id) SELECT 'pending' status, NOW() created, '1' user_id, o.report_id cdrr_id FROM tbl_order o INNER JOIN tbl_facility f ON f.id = o.facility GROUP BY o.facility, o.period;

	/*Update dimension to drug_id*/
	UPDATE tbl_order o INNER JOIN tbl_dhis_elements de ON de.dhis_code = o.dimension SET o.dimension = de.target_id;

	/*Upsert cdrr_item based on cdrr and drug_id*/
	DECLARE curs CURSOR FOR  SELECT CONCAT_WS(',', GROUP_CONCAT(DISTINCT o.category SEPARATOR ','), 'cdrr_id', 'drug_id'), CONCAT_WS(',', GROUP_CONCAT(o.value SEPARATOR ','), report_id, dimension) FROM tbl_order o GROUP BY report_id, dimension;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET bDone = 1;

	OPEN curs;

	SET bDone = 0;
	REPEAT
		FETCH curs INTO k,v;

		SET @sqlv=CONCAT('REPLACE INTO tbl_cdrr_item (', k, ') VALUES (', v, ')');
		PREPARE stmt FROM @sqlv;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

	UNTIL bDone END REPEAT;

	CLOSE curs;

	TRUNCATE tbl_order;
END//
DELIMITER ;

/*Save maps*/
DROP PROCEDURE IF EXISTS proc_save_maps;
DELIMITER //
CREATE PROCEDURE proc_save_maps()
BEGIN
	DECLARE bDone INT;
	DECLARE k VARCHAR(255);
	DECLARE v VARCHAR(255);

	/*Update dhiscode to facility_id*/
	UPDATE tbl_order o INNER JOIN tbl_facility f ON f.dhiscode = o.facility SET o.facility = f.id;

	/*Format period to period_begin date type*/
	UPDATE tbl_order o SET o.period = DATE_FORMAT(STR_TO_DATE(o.period, '%Y%m') , "%Y-%m-01");

	/*Upsert maps from tbl_order*/
	REPLACE INTO tbl_maps(status, created, code, period_begin, period_end, facility_id) SELECT 'pending' status, NOW() created, 'F-MAPS' code, o.period period_begin, LAST_DAY(o.period) period_end, o.facility facility_id FROM tbl_order o INNER JOIN tbl_facility f ON f.id = o.facility GROUP BY o.facility, o.period;

	/*Update report_id to maps_id*/
	UPDATE tbl_order o INNER JOIN tbl_maps m ON m.facility_id = o.facility AND o.period = m.period_begin SET o.report_id = m.id;

	/*Upsert maps_log based on maps*/
	REPLACE INTO tbl_maps_log(description, created, user_id, maps_id) SELECT 'pending' status, NOW() created, '1' user_id, o.report_id maps_id FROM tbl_order o INNER JOIN tbl_facility f ON f.id = o.facility GROUP BY o.facility, o.period;

	/*Update dimension to regimen_id*/
	UPDATE tbl_order o INNER JOIN tbl_dhis_elements de ON de.dhis_code = o.dimension SET o.dimension = de.target_id;

	/*Upsert maps_item based on maps and regimen_id*/
	DECLARE curs CURSOR FOR  SELECT CONCAT_WS(',', GROUP_CONCAT(DISTINCT o.category SEPARATOR ','), 'maps_id', 'regimen_id'), CONCAT_WS(',', GROUP_CONCAT(o.value SEPARATOR ','), report_id, dimension) FROM tbl_order o GROUP BY report_id, dimension;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET bDone = 1;

	OPEN curs;

	SET bDone = 0;
	REPEAT
		FETCH curs INTO k,v;

		SET @sqlv=CONCAT('REPLACE INTO tbl_maps_item (', k, ') VALUES (', v, ')');
		PREPARE stmt FROM @sqlv;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;

	UNTIL bDone END REPEAT;

	CLOSE curs;

	TRUNCATE tbl_order;
END//
DELIMITER ;