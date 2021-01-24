declare
begin
 emp_pkg.add_employee(80005, 'John Smith', 'CEO',90005 , TO_DATE('01/01/95','DD/MM/RRRR'), 100000, 1);
end;
/

declare
  v_emp_id employees.employee_id%type := 90005;
  v_pecrent number := 10;
  v_inc_dec varchar2(20) := 'INCREMENT';
begin
  emp_pkg.update_salary(v_emp_id, v_pecrent, v_inc_dec);
end;
/

declare
  v_emp_id employees.employee_id%type := 90007;
  v_dept_id employees.department_id%type := 3;
begin
  emp_pkg.transfer_employee(v_emp_id, v_dept_id);
end;
/


declare
  v_emp_id employees.employee_id%type := 90007;
  v_salary employees.salary%type;
begin
  v_salary := emp_pkg.get_employee_salary(v_emp_id);
  dbms_output.put_line('Salary for Emp. Id '||v_emp_id|| ' is '||v_salary);
end;
/

select * from table(emp_pkg.dept_wise_emp(4));
select * from vu_dept_wise_emp where department_id = 4;
select * from vu_dept_wise_salary;
