DROP DATABASE IF EXISTS railway;
CREATE DATABASE railway;
USE railway;

CREATE TABLE students (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    unix_id VARCHAR(10) NOT NULL UNIQUE
);

CREATE TABLE courses (
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    moniker VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    department VARCHAR(50) NOT NULL
);

CREATE TABLE prerequisites(
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    course VARCHAR(255) NOT NULL,
    prereq VARCHAR(255) NOT NULL,
    min_grade INTEGER NOT NULL,
    FOREIGN KEY(course) REFERENCES courses(moniker), 
    FOREIGN KEY(prereq) REFERENCES courses(moniker), 
    CHECK(min_grade >= 0 AND min_grade <= 100)
);

CREATE TABLE student_course(
    id INTEGER PRIMARY KEY AUTO_INCREMENT,
    student VARCHAR(10) NOT NULL,
    course VARCHAR(255) NOT NULL,
    year INTEGER,
    grade INTEGER,
    FOREIGN KEY(student) REFERENCES students(unix_id), 
    FOREIGN KEY(course) REFERENCES courses(moniker), 
    UNIQUE(student, course, year),
    CHECK(grade >= 0 AND grade <= 100)
);

CREATE TRIGGER before_student_course_insert
    BEFORE INSERT
    ON student_course
    FOR EACH ROW
BEGIN
    DECLARE unmet_prereqs_count INT;

    -- Check if there are any unmet prerequisites
    SELECT COUNT(*)
    INTO unmet_prereqs_count
    FROM prerequisites p
    WHERE p.course = NEW.course
    AND p.prereq NOT IN (
        SELECT sc.course
        FROM student_course sc
        WHERE sc.student = NEW.student
        AND sc.grade >= p.min_grade
    );

    -- If there are unmet prerequisites, raise an error
    IF unmet_prereqs_count > 0 THEN
        SET @message = CONCAT('Student ', NEW.student, ' cannot take course ', NEW.course, ' because not all prerequisites are met');
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = @message;
    END IF;
END;

CREATE TABLE IF NOT EXISTS letter_grade(
    grade INTEGER NOT NULL,
    letter VARCHAR(1) NOT NULL,
    check (grade >= 0 and grade <=100)
);