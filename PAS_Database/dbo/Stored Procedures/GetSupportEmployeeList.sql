/*************************************************************           
 ** File:   [GetSupportEmployeeList]         
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used GetSupportEmployeeList
 ** Purpose:         
 ** Date:   15/11/2024     
             
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    15/11/2024  Ekta Chandegra     Created
	2    17/01/2025  Ekta Chandegra     Retrieve support user email


exec dbo.GetSupportEmployeeList 

************************************************************************/

CREATE     PROCEDURE [dbo].[GetSupportEmployeeList]
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	DECLARE @MasterCompanyId int = 1
	DECLARE @RoleName NVARCHAR(100) = 'Support User'
	BEGIN TRY  
		BEGIN
			SELECT DISTINCT
			EMP.EmployeeId AS VALUE,
			EMP.FirstName + ' ' + EMP.LastName AS Label,
			EMP.Email
			FROM [dbo].[Employee] EMP WITH (NOLOCK)
			LEFT JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON  EMP.EmployeeId = EUR.EmployeeId
			LEFT JOIN [dbo].[UserRole] UR WITH (NOLOCK) ON EUR.RoleId = UR.Id 
			WHERE UR.Name = @RoleName
			AND EMP.MasterCompanyId =  @MasterCompanyId
			AND ISNULL(EMP.IsActive,0) = 1 
			AND ISNULL(EMP.IsDeleted,0) = 0
		END 
	END TRY
	BEGIN CATCH
	DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetSupportEmployeeList'
			, @ProcedureParameters VARCHAR(3000)  = ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END