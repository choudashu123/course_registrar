CREATE TRIGGER before_student_course_insert
    BEFORE INSERT
    ON student_course
    FOR EACH ROW
BEGIN

    DROP TEMPORARY TABLE IF EXISTS temp_prereq;
    DROP TEMPORARY TABLE IF EXISTS unmet_prereqs;

    CREATE TEMPORARY TABLE if NOT EXISTS temp_prereq(
        prereq VARCHAR(10) REFERENCES courses (moniker),
        min_grade INTEGER
    );
    CREATE TEMPORARY TABLE IF NOT EXISTS unmet_prereqs(
        prereq VARCHAR(10) REFERENCES courses (moniker)
    );

    INSERT INTO temp_prereq (prereq, min_grade)
    SELECT prereq, min_grade
    FROM prerequisites as p
    WHERE p.course = NEW.course;

    INSERT INTO unmet_prereqs (prereq)
    SELECT prereq
    FROM temp_prereq as tp
    WHERE tp.prereq NOT IN
        (SELECT sc.course FROM student_course as sc WHERE sc.student = NEW.student AND sc.grade > tp.min_grade);

    if (exists(SELECT 1 FROM unmet_prereqs) > 0 ) THEN
        SET @message = CONCAT('Student', NEW.student, 'cannot take course', NEW.course, "because not all prereqs are met");
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = @message;
    end if;
end;
