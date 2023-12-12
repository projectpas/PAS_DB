


CREATE    VIEW [dbo].[View_Employee_Cert]
AS
	SELECT FirstName + ' ' + LastName AS EmployeeName, EmployeeId, MasterCompanyId, IsActive, IsDeleted
	FROM  dbo.Employee WITH(NOLOCK) WHERE [EmployeeCertifyingStaff] = 1