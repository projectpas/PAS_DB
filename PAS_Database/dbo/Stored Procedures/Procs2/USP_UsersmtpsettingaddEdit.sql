/*************************************************************
 ** File:   [USP_UsersmtpsettingaddEdit]
 ** Author:   Unknown 
 ** Description: update smtp setting 
 ** Purpose:   
 ** Date:   Unknown

 ** PARAMETERS:
   
 ** RETURN VALUE:
 
 **************************************************************
  ** Change History
 **************************************************************
 ** S NO   Date		Author				Change	Description 
 ** --   ---------------  --------------------------------
	1	Unknown
	2	11/26/2024	Abhishek Jirawla	Added email update in the query
	3   07-04-2025  Shrey Chandegara    modified due to PN-12082
**************************************************************/
CREATE    Procedure [dbo].[USP_UsersmtpsettingaddEdit]
@smtpsettingId  bigint=0,
@EmployeeId bigint ,
@smtpserver  varchar(256)='',
@emailpassword varchar(56)='',
@portno int=0,
@emailtype int=0,
@verifyemail bit=0,
@Email VARCHAR(200) = NULL,
@IsIncludeInCC BIT = 0
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   

BEGIN TRY
BEGIN TRANSACTION
if(@smtpsettingId>0)
	begin
		INSERT INTO DBO.UsersmtpsettingAudit (EmployeeId,smtpserver,emailpassword,portno,emailtype,verifyemail,CreatedDate,UpdatedDate)
		SELECT EmployeeId,smtpserver,emailpassword,portno,emailtype,verifyemail,CreatedDate,UpdatedDate FROM DBO.Usersmtpsetting WITH (NOLOCK) WHERE smtpsettingId=@smtpsettingId

		UPDATE DBO.Usersmtpsetting SET EmployeeId=@EmployeeId,smtpserver=@smtpserver,emailpassword=@emailpassword,portno=@portno, 
		emailtype=@emailtype ,verifyemail=CASE WHEN @emailtype=1 THEN @verifyemail ELSE verifyemail END ,UpdatedDate=getdate() WHERE smtpsettingId=@smtpsettingId

		UPDATE DBO.Employee
		SET Email = @Email,IsIncludeInCC = @IsIncludeInCC
		WHERE EmployeeId = @EmployeeId	
	END
else
	begin
		INSERT INTO DBO.Usersmtpsetting (EmployeeId,smtpserver,emailpassword,portno,emailtype,verifyemail)
		VALUES (@EmployeeId,@smtpserver,@emailpassword,@portno,@emailtype,
		CASE WHEN @emailtype=1 THEN @verifyemail ELSE 1 END)
		SET @smtpsettingId=@@IDENTITY

		UPDATE DBO.Employee
		SET Email = @Email,IsIncludeInCC = @IsIncludeInCC
		WHERE EmployeeId = @EmployeeId	
	END

	SELECT @smtpsettingId as smtpsettingId

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