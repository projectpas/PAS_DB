
create    Procedure USP_UsersmtpsettingaddEdit
@smtpsettingId  bigint=0,
@EmployeeId bigint ,
@smtpserver  varchar(256)='',
@emailpassword varchar(56)='',
@portno int=0,
@emailtype int=0,
@verifyemail bit=0
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   

BEGIN TRY
BEGIN TRANSACTION
if(@smtpsettingId>0)
	begin

	insert into UsersmtpsettingAudit (EmployeeId,smtpserver,emailpassword,portno,emailtype,verifyemail,CreatedDate,UpdatedDate)
	select EmployeeId,smtpserver,emailpassword,portno,emailtype,verifyemail,CreatedDate,UpdatedDate from Usersmtpsetting where smtpsettingId=@smtpsettingId

	update Usersmtpsetting set EmployeeId=@EmployeeId,smtpserver=@smtpserver,emailpassword=@emailpassword,portno=@portno 
	,emailtype=@emailtype ,verifyemail=case when @emailtype=1 then @verifyemail else verifyemail end ,UpdatedDate=getdate() where smtpsettingId=@smtpsettingId
	
	end
else
	begin
		insert into Usersmtpsetting (EmployeeId,smtpserver,emailpassword,portno,emailtype,verifyemail)
		values (@EmployeeId,@smtpserver,@emailpassword,@portno,@emailtype,
		case when @emailtype=1 then @verifyemail else 1 end)
		set @smtpsettingId=@@IDENTITY
	end

	select @smtpsettingId as smtpsettingId

COMMIT  TRANSACTION

END TRY    
BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_UsersmtpsettingaddEdit' 
             , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@smtpsettingId, '') as Varchar(100)) + 
										  '@Parameter2 = '''+ CAST(ISNULL(@EmployeeID, '') as Varchar(100))+
										  '@Parameter3 = '''+ CAST(ISNULL(@smtpserver, '') as Varchar(100))+
										  '@Parameter4 = '''+ CAST(ISNULL(@emailpassword, '') as Varchar(100))+
										  '@Parameter5 = '''+ CAST(ISNULL(@portno, '') as Varchar(100))

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