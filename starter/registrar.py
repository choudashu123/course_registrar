import typer
from os import environ as env
from rich.console import Console
from rich.table import Table
from datetime import datetime
from database import reset, add_a_student, add_a_new_course, show_prereq_for, add_a_prerequisites, initialize_data, show_students_by, \
    show_courses_by, enroll_student, set_grade, unenroll_student, show_courses_a_student_is_taking, get_transcript_for_a_student \
    , get_courses_with_most_enrollment, get_top_performing_students
app = typer.Typer()
console=Console()

def pretty_table(with_headers, data, in_color):
    table = Table(*with_headers, show_header=True, header_style=f"bold {in_color}")
    for row in data :
        table.add_row(*map(str, row))
    console.print(table)

@app.command()
def add_student(first_name: str, last_name: str, unix_id: str):
    add_a_student(first_name, last_name, unix_id)
    console.print("adding student")

@app.command()
def add_course(moniker: str, name:str, department:str):
    add_a_new_course(moniker, name, department)
    console.print("course added")
    
@app.command()
def add_prereq(course: str, prereq: str, min_grade: int = 50 ):
    add_a_prerequisites(course, prereq, min_grade)
    console.print("added a prereq")

@app.command()
def reset_database(verbose: bool =False, with_data: bool = True):
    # --no-with_data
    # --with_data
    answer=input("this will delete all the data. Are you sure? (y/n): ")
    if verbose :
        env["MYSQL_VERBOSE"] = 'YES'
    if answer.strip().lower()=="y":
        reset()
        typer.echo("Database reset successfully")

        if with_data:
            initialize_data()
            typer.echo("Data Initialize Successfully")
    else:
        typer.echo("Database reset aborted")

@app.command()
def show_prereq(course: str):
    pretty_table(["Prerequisites", "Min_Grade"], data=show_prereq_for(course), in_color="yellow")

@app.command()
def show_students(last_name:str):
    data=show_students_by(last_name)
    pretty_table(['first_name', 'last_name', 'unix_id'], data=data, in_color='blue')

@app.command()
def show_courses(department:str):
    data=show_courses_by(department)
    pretty_table(['moniker', 'name', 'department'], data=data, in_color='blue')

@app.command()
def enroll(student:str, course:str, year:int = datetime.now().year):
    enroll_student(student, course, year)

@app.command()
def grade(student:str, course:str, grade: int, year:int = datetime.now().year):
    set_grade(student, course, grade, year)

@app.command()
def unenroll(student:str, course:str, year:int = datetime.now().year):
    unenroll_student(student, course, year)

@app.command()
def show_student_courses(student: str):
    data = show_courses_a_student_is_taking(student)
    pretty_table(['Courses', 'Year'],data, in_color="green")

@app.command()
def transcript(student:str):
    data = get_transcript_for_a_student(student)
    pretty_table(['course', 'year', 'grade', 'letter_grade'], data=data, in_color="magenta")
    console.print(f"Average GPA : {sum(row[2] for row in data)/len(data):.2f}")

@app.command()
def most_enrollments(n:int=10):
    data=get_courses_with_most_enrollment(n)
    pretty_table(['courses', 'name', 'enrollments'], data=data, in_color='blue')

@app.command()
def top_students(n:int=10):
    data=get_top_performing_students(n)
    pretty_table(['UnixID', 'first_name', 'last_name', 'Courses', 'Cum. GPA'], data=data, in_color='blue')


if __name__ == "__main__":
    app()
 