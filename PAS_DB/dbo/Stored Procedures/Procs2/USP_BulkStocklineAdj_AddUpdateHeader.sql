/*************************************************************           
 ** File:   [USP_BulkStocklineAdj_AddUpdateHeader]           
 ** Author:  AMIT GHEDIYA
 ** Description: This stored procedure is used to create and update bulk stockline adjustment header
 ** Purpose:         
 ** Date:   27/09/2023     
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date           Author					Change Description            
 ** --   --------       -------				   --------------------------------          
    1    27/09/2023     AMIT GHEDIYA			Created
	2    11/10/2023     AMIT GHEDIYA			Added status & statusid
     
-- EXEC USP_BulkStocklineAdj_AddUpdateHeader 
************************************************************************/
CREATE      PROCEDURE [dbo].[USP_BulkStocklineAdj_AddUpdateHeader]
	@BulkStkLineAdjHeaderId BIGINT=NULL,
	@BulkStkLineAdjNumber VARCHAR(50)=NULL,
	@MasterCompanyId INT=NULL,
	@CreatedBy VARCHAR(256)=NULL,
	@UpdatedBy VARCHAR(256)=NULL,
	@CreatedDate DATETIME2(7)=NULL,
	@UpdatedDate DATETIME2(7)=NULL,
	@IsActive BIT=NULL,
	@IsDeleted BIT=NULL,
	@StatusId INT=NULL,
	@Status VARCHAR(50)=NULL,
	@stockLineAdjustmentTypeId INT=NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY 
		BEGIN TRANSACTION
		BEGIN
			IF (@BulkStkLineAdjHeaderId IS NULL OR @BulkStkLineAdjHeaderId=0)
			BEGIN 
				INSERT INTO [dbo].[BulkStockLineAdjustment]([BulkStkLineAdjNumber],[MasterCompanyId],[Status],[StatusId],
                                               [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
										VALUES (@BulkStkLineAdjNumber,@MasterCompanyId,@Status,@StatusId,
												@CreatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),@IsActive,@IsDeleted);

				SELECT	IDENT_CURRENT('BulkStockLineAdjustment') AS BulkStkLineAdjId;

			END		
			ELSE
			BEGIN
				UPDATE [dbo].[BulkStockLineAdjustment] 
										  SET [UpdatedBy]=@UpdatedBy,[UpdatedDate]=GETUTCDATE(),
											  [Status]=@Status,[StatusId]=@StatusId
									    WHERE [BulkStkLineAdjId] = @BulkStkLineAdjHeaderId;
				SELECT @BulkStkLineAdjHeaderId AS BulkStkLineAdjId;

			END
		END
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_BulkStocklineAdj_AddUpdateHeader' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@BulkStkLineAdjHeaderId, '') AS varchar(100))
													+ '@Parameter2 = ''' + CAST(ISNULL(@BulkStkLineAdjNumber, '') AS varchar(100)) 
													+ '@Parameter6 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END