SET DEFINE OFF;

/* *****************************************************************************
Written by Faizan Ahmed on 24-Jan-2021
***************************************************************************** */

/* *****************************************************************************
Create Tables and Insert Data
***************************************************************************** */
CREATE TABLE departments (
       department_id   NUMBER(5) NOT NULL,
       department_name VARCHAR2(50) NOT NULL,
       location        VARCHAR2(50) NOT NULL,
       CONSTRAINT pk_department PRIMARY KEY (department_id)
);

INSERT INTO departments (department_id, department_name, location) VALUES (1, 'Management', 'London');
INSERT INTO departments (department_id, department_name, location) VALUES (2, 'Engineering', 'Cardiff');
INSERT INTO departments (department_id, department_name, location) VALUES (3, 'Research & Development', 'Edinburgh');
INSERT INTO departments (department_id, department_name, location) VALUES (4, 'Sales', 'Belfast');

CREATE TABLE employees (
       employee_id   NUMBER(10) NOT NULL,
       employee_name VARCHAR2(50) NOT NULL,
       job_title     VARCHAR2(50) NOT NULL,
       manager_id    NUMBER(10),
       date_hired    DATE NOT NULL,
       salary        NUMBER(10) NOT NULL,
       department_id NUMBER(5) NOT NULL,
       CONSTRAINT pk_employees PRIMARY KEY (employee_id),
       CONSTRAINT fk_emp_manager_id FOREIGN KEY (manager_id) REFERENCES employees(employee_id),
       CONSTRAINT fk_emp_department_id FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id) VALUES (90001, 'John Smith', 'CEO', NULL, TO_DATE('01/01/95','DD/MM/RRRR'), 100000, 1);
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id) VALUES (90002, 'Jimmy Willis', 'Manager', 90001, TO_DATE('23/09/03','DD/MM/RRRR'), 52500, 4);
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id) VALUES (90003, 'Roxy Jones', 'Salesperson', 90002, TO_DATE('11/02/17','DD/MM/RRRR'), 35000, 4);
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id) VALUES (90004, 'Selwyn Field', 'Salesperson', 90003, TO_DATE('20/05/15','DD/MM/RRRR'), 32000, 4);
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id) VALUES (90006, 'Sarah Phelps', 'Manager', 90001, TO_DATE('21/03/15','DD/MM/RRRR'), 45000, 2);
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id) VALUES (90005, 'David Hallett', 'Engineer', 90006, TO_DATE('17/04/18','DD/MM/RRRR'), 40000, 2);
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id) VALUES (90007, 'Louise Harper', 'Engineer', 90006, TO_DATE('01/01/13','DD/MM/RRRR'), 47000, 2);
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id) VALUES (90009, 'Gus Jones', 'Manager', 90001, TO_DATE('15/05/18','DD/MM/RRRR'), 50000, 3);
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id) VALUES (90008, 'Tina Hart', 'Engineer', 90009, TO_DATE('28/07/14','DD/MM/RRRR'), 45000, 3);
INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id) VALUES (90010, 'Mildred Hall', 'Secretary', 90001, TO_DATE('12/10/96','DD/MM/RRRR'), 35000, 1);

/* *****************************************************************************
Create Package
***************************************************************************** */

CREATE OR REPLACE PACKAGE emp_pkg AS

 TYPE emp_record IS RECORD (
    employee_id     employees.employee_id%TYPE,
    employee_name   employees.employee_name%TYPE,
    job_title       employees.job_title%TYPE,
    manager_id      employees.manager_id%TYPE,
    manager_name    employees.employee_name%TYPE,
    date_hired      employees.date_hired%TYPE,
    salary          employees.salary%TYPE,
    department_id   employees.department_id%TYPE,
    department_name departments.department_name%TYPE,
    location        departments.location%TYPE
 );

 TYPE emp_type IS TABLE OF emp_record;

 PROCEDURE add_employee (p_employee_id   IN employees.employee_id%TYPE,
                         p_employee_name IN employees.employee_name%TYPE,
                         p_job_title     IN employees.job_title%TYPE,
                         p_manager_id    IN employees.manager_id%TYPE,
                         p_date_hired    IN employees.date_hired%TYPE,
                         p_salary        IN employees.salary%TYPE,
                         p_department_id IN employees.department_id%TYPE);

 PROCEDURE update_salary(p_employee_id IN employees.employee_id%TYPE,
                         p_percentage  IN NUMBER,
                         p_inc_dec     IN VARCHAR2 DEFAULT 'INCREMENT');

 PROCEDURE transfer_employee(p_employee_id       IN employees.employee_id%TYPE,
                             p_new_department_id IN employees.department_id%TYPE);

 FUNCTION get_employee_salary(p_employee_id IN employees.employee_id%TYPE) RETURN NUMBER;

 FUNCTION dept_wise_emp (p_department_id IN employees.department_id%TYPE)
 RETURN emp_type PIPELINED;

END emp_pkg;
/

CREATE OR REPLACE PACKAGE BODY emp_pkg AS

/* *****************************************************************************
Procedure to add new employee
***************************************************************************** */

 PROCEDURE add_employee (p_employee_id   IN employees.employee_id%TYPE,
                         p_employee_name IN employees.employee_name%TYPE,
                         p_job_title     IN employees.job_title%TYPE,
                         p_manager_id    IN employees.manager_id%TYPE,
                         p_date_hired    IN employees.date_hired%TYPE,
                         p_salary        IN employees.salary%TYPE,
                         p_department_id IN employees.department_id%TYPE)
 IS

 e_employee_already_exist EXCEPTION;
 PRAGMA exception_init(e_employee_already_exist, -20001);

 e_department_not_found EXCEPTION;
 PRAGMA exception_init(e_department_not_found, -20002);

 e_manager_not_found EXCEPTION;
 PRAGMA exception_init(e_manager_not_found, -20003);

 v_error_message VARCHAR2(4000);
 v_dummy varchar2(1);

 BEGIN

  BEGIN
    SELECT 'X'
    INTO v_dummy
    FROM departments
    WHERE department_id = p_department_id;
  EXCEPTION
       WHEN NO_DATA_FOUND
       THEN RAISE e_department_not_found;
  END;

  IF p_manager_id IS NOT NULL THEN

     BEGIN
       SELECT 'X'
       INTO v_dummy
       FROM employees
       WHERE employee_id = p_manager_id;
     EXCEPTION
          WHEN NO_DATA_FOUND
          THEN RAISE e_manager_not_found;
     END;

  END IF;

  BEGIN

   INSERT INTO employees (employee_id, employee_name, job_title, manager_id, date_hired, salary, department_id)
   VALUES (p_employee_id, p_employee_name, p_job_title, p_manager_id, p_date_hired, p_salary, p_department_id);

  EXCEPTION
        WHEN DUP_VAL_ON_INDEX
        THEN RAISE e_employee_already_exist;
  END;

 EXCEPTION

      WHEN e_employee_already_exist
      THEN v_error_message := 'Employee Id '||p_employee_id||' already exists';
           RAISE_APPLICATION_ERROR(-20001, v_error_message);

      WHEN e_department_not_found
      THEN v_error_message := 'Department Id '||p_department_id||' does not exist';
           RAISE_APPLICATION_ERROR(-20002, v_error_message);

      WHEN e_manager_not_found
      THEN v_error_message := 'Manger Employee Id '||p_manager_id||' does not exist';
           RAISE_APPLICATION_ERROR(-20002, v_error_message);

 END add_employee;

/* *****************************************************************************
Procedure to Increase/Decrease Employee Salary 
***************************************************************************** */

 PROCEDURE update_salary(p_employee_id IN employees.employee_id%TYPE,
                         p_percentage  IN NUMBER,
                         p_inc_dec     IN VARCHAR2 DEFAULT 'INCREMENT')
 IS

 e_employee_not_found EXCEPTION;
 PRAGMA exception_init(e_employee_not_found, -20001);
 
 e_invalid_value EXCEPTION;
 PRAGMA exception_init(e_invalid_value, -20002);
 
 v_error_message VARCHAR2(4000);

 BEGIN

   IF UPPER(p_inc_dec) IN ('INCREMENT','DECREMENT')
   THEN

     UPDATE employees
     SET salary = CASE
                     WHEN UPPER(p_inc_dec) = 'INCREMENT'  THEN
                          salary + ((salary * p_percentage)/100)
                     WHEN UPPER(p_inc_dec) = 'DECREMENT' THEN
                          salary - ((salary * p_percentage)/100)
                  END
     WHERE employee_id = p_employee_id;

     IF SQL%NOTFOUND THEN

       RAISE e_employee_not_found;

     END IF;

   ELSE
 
     RAISE e_invalid_value;

   END IF;

 EXCEPTION

    WHEN e_employee_not_found
    THEN v_error_message := 'Employee Id '||p_employee_id||' does not exist';
         RAISE_APPLICATION_ERROR(-20001, v_error_message);   

    WHEN e_invalid_value
    THEN v_error_message := 'Valid values are INCREMENT or DECREMENT';
         RAISE_APPLICATION_ERROR(-20002, v_error_message);   

 END update_salary;

/* *****************************************************************************
Procedure to transfer employee from one department to anonther
***************************************************************************** */

 PROCEDURE transfer_employee(p_employee_id       IN employees.employee_id%TYPE,
                             p_new_department_id IN employees.department_id%TYPE)

 IS

 e_employee_not_found EXCEPTION;
 PRAGMA exception_init(e_employee_not_found, -20001);

 e_department_not_found EXCEPTION;
 PRAGMA exception_init(e_department_not_found, -2291);

 v_error_message VARCHAR2(4000);

 BEGIN

   UPDATE employees
   SET department_id = p_new_department_id
   WHERE employee_id = p_employee_id;

   IF SQL%NOTFOUND THEN
      RAISE e_employee_not_found;
   END IF;

 EXCEPTION

      WHEN e_employee_not_found
      THEN v_error_message := 'Employee Id '||p_employee_id||' does not exist';
           RAISE_APPLICATION_ERROR(-20001, v_error_message);

      WHEN e_department_not_found
      THEN v_error_message := 'Department Id '||p_new_department_id||' does not exist';
           RAISE_APPLICATION_ERROR(-20002, v_error_message);

 END transfer_employee;

/* *****************************************************************************
Function to get the salary of a employee
***************************************************************************** */

 FUNCTION get_employee_salary(p_employee_id IN employees.employee_id%TYPE)
 RETURN NUMBER IS

 e_employee_not_found EXCEPTION;
 PRAGMA exception_init(e_employee_not_found, -20001);

 CURSOR c_emp_sal(cp_employee_id IN employees.employee_id%TYPE)
 IS
        SELECT salary
        FROM employees
        WHERE employee_id = cp_employee_id;

 v_salary employees.salary%TYPE;
 v_error_message VARCHAR2(4000);

 BEGIN

   OPEN c_emp_sal(p_employee_id);
     FETCH c_emp_sal INTO v_salary;
     IF c_emp_sal%ROWCOUNT = 0 THEN
        CLOSE c_emp_sal;
        RAISE e_employee_not_found;
     END IF;
   CLOSE c_emp_sal;
   
   RETURN v_salary;

 EXCEPTION

      WHEN e_employee_not_found
      THEN v_error_message := 'Employee Id '||p_employee_id||' does not exist';
           RAISE_APPLICATION_ERROR(-20001, v_error_message);

      WHEN OTHERS
      THEN v_error_message := SQLERRM;
           RAISE_APPLICATION_ERROR(-20001, v_error_message);

 END get_employee_salary;

/* *****************************************************************************
Function to get the list of employees
***************************************************************************** */

 FUNCTION dept_wise_emp (p_department_id IN employees.department_id%TYPE)
 RETURN emp_type PIPELINED IS

   CURSOR emp_cur
   IS
   SELECT e.employee_id, e.employee_name, e.job_title, e.manager_id, m.employee_name as manager_name, e.date_hired, e.salary, e.department_id, d.department_name, d.location
   FROM employees e
   LEFT JOIN employees m ON (m.employee_id = e.manager_id)
   JOIN departments d on (d.department_id = e.department_id)
   WHERE e.department_id = p_department_id;
  
   emp_rec emp_record;

 BEGIN

   FOR emp_cur_rec IN emp_cur
   LOOP

     emp_rec.employee_id     := emp_cur_rec.employee_id;
     emp_rec.employee_name   := emp_cur_rec.employee_name;
     emp_rec.job_title       := emp_cur_rec.job_title;
     emp_rec.manager_id      := emp_cur_rec.manager_id;
     emp_rec.manager_name    := emp_cur_rec.employee_name;
     emp_rec.date_hired      := emp_cur_rec.date_hired;
     emp_rec.salary          := emp_cur_rec.salary;
     emp_rec.department_id   := emp_cur_rec.department_id;
     emp_rec.department_name := emp_cur_rec.department_name;
     emp_rec.location        := emp_cur_rec.location;

     PIPE ROW (emp_rec); 

   END LOOP;
  
 END dept_wise_emp;  

END emp_pkg;
/

CREATE OR REPLACE VIEW vu_dept_wise_emp AS
   SELECT e.employee_id, e.employee_name, e.job_title, e.manager_id, m.employee_name as manager_name, e.date_hired, e.salary, e.department_id, d.department_name, d.location
   FROM employees e
   LEFT JOIN employees m ON (m.employee_id = e.manager_id)
   JOIN departments d on (d.department_id = e.department_id);

CREATE OR REPLACE VIEW vu_dept_wise_salary AS
   SELECT e.department_id, d.department_name, SUM(e.salary) dept_salary
   FROM employees e
   JOIN departments d ON (d.department_id = e.department_id)
   GROUP BY e.department_id, d.department_name;
 
