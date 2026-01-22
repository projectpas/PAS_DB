

CREATE   VIEW [dbo].[View_Employee]
AS
SELECT FirstName + ' ' + LastName AS EmployeeName, EmployeeId, MasterCompanyId, IsActive, IsDeleted
FROM     dbo.Employee