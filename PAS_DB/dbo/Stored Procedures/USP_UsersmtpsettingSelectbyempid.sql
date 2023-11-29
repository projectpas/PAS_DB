
--exec USP_UsersmtpsettingSelectbyempid 3
create    Procedure USP_UsersmtpsettingSelectbyempid
@EmployeeId bigint 
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   

	BEGIN TRY

	select isnull(smtpsettingId,0)smtpsettingId,Employee.EmployeeId,smtpserver,emailpassword,isnull(portno,0)portno,email,emailtype,verifyemail from Employee 
	left join Usersmtpsetting on Employee.EmployeeId=Usersmtpsetting.EmployeeId
	where Employee.EmployeeId=@EmployeeId
			
			
	END TRY    
	BEGIN CATCH      
		
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_UsersmtpsettingSelectbyempid' 
             , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@EmployeeID, '') as Varchar(100))  
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