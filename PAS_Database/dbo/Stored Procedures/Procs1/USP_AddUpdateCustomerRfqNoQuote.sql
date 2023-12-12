/*************************************************************           
 ** File:   [USP_AddUpdateCustomerRfqNoQuote]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used USP_AddUpdateCustomerRfqNoQuote
 ** Purpose:         
 ** Date:   24/02/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    24/02/2023  Amit Ghediya    Created
     
-- EXEC USP_AddUpdateCustomerRfqNoQuote
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_AddUpdateCustomerRfqNoQuote]
	@RfqId BIGINT,
	@MasterCompanyId INT,
	@Note VARCHAR(250),
	@IsQuote INT,
	@CreatedBy VARCHAR(200),
	@UpdatedBy VARCHAR(200),
	@CreatedDate DATETIME,
	@UpdatedDate DATETIME
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

					DECLARE @CustomerRfqQuoteId BIGINT;

		            --------------------- Insert into Rfq NO Quote table ------------------

					INSERT INTO [dbo].[CustomerRfqQuote]
							([RfqId] ,[MasterCompanyId] , [Note],
							[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
					VALUES (@RfqId ,@MasterCompanyId ,@Note,
							@CreatedBy ,GETDATE() ,@UpdatedBy ,GETDATE() ,1 ,0);

					SELECT @CustomerRfqQuoteId = SCOPE_IDENTITY();	

					------------------------ Update Customer RFQ table ------------

					UPDATE [dbo].[CustomerRfq]
							SET IsQuote = @IsQuote
					WHERE RfqId = @RfqId;

				SELECT @CustomerRfqQuoteId AS CustomerRfqQuoteId;
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_AddUpdateCustomerRfqNoQuote' 
            , @ProcedureParameters VARCHAR(3000) = '@RfqId = ''' + CAST(ISNULL(@RfqId, '') as varchar(100))
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