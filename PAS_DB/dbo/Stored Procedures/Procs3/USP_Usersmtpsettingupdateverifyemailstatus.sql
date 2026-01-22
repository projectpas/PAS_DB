create    Procedure USP_Usersmtpsettingupdateverifyemailstatus
@EmployeeId bigint=0,
@verifyemail bit=0
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   

BEGIN TRY
BEGIN TRANSACTION
if EXISTS(select * from Usersmtpsetting where EmployeeId=@EmployeeId)
	begin
		
		insert into UsersmtpsettingAudit (EmployeeId,smtpserver,emailpassword,portno,emailtype,verifyemail,CreatedDate,UpdatedDate)
	    select EmployeeId,smtpserver,emailpassword,portno,emailtype,verifyemail,CreatedDate,UpdatedDate 
		from Usersmtpsetting  where EmployeeId=@EmployeeId

		update Usersmtpsetting set verifyemail=@verifyemail,UpdatedDate=getdate() where EmployeeId=@EmployeeId

	end
else
	begin
		insert into Usersmtpsetting (EmployeeId,smtpserver,emailpassword,portno,emailtype,verifyemail)
		values (@EmployeeId,'','','',1,@verifyemail)
	end

	select smtpsettingId from Usersmtpsetting where EmployeeId=@EmployeeId 

COMMIT  TRANSACTION

END TRY    
BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_Usersmtpsettingupdateverifyemailstatus' 
             , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@EmployeeID, '') as Varchar(100)) + 
										  '@Parameter2 = '''+ CAST(ISNULL(@verifyemail, '') as Varchar(100))
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