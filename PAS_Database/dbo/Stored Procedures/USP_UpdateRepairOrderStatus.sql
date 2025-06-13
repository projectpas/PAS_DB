/*************************************************************           
 ** File:   [USP_UpdateRepairOrderStatus]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used to update repair Order status
 ** Date:   28th-May-2025
 ** PARAMETERS: 
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    28-May-2025		Devendra Shekh		Created 
    2    12-June-2025		Devendra Shekh		Added Else Part to Update RO Status

-- EXEC [UpdateSalesOrderStatus] 1316,11,1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateRepairOrderStatus]
	@RepairOrderId BIGINT,
	@RepairOrderStatus BIGINT,
	@IsFromShipping BIT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION  
			DECLARE @ROPartDataCount BIGINT,
				@ROShippingCount BIGINT,
				@StatusName VARCHAR(MAX),
				@ROShippingItemCount BIGINT,
				@ROShippedStatusId BIGINT,
				@ROOpenStatusId BIGINT;

			SELECT @ROPartDataCount = ISNULL(SUM(QuantityOrdered), 0) FROM [DBO].[RepairOrderPart] WITH(NOLOCK) WHERE [RepairOrderId] = @RepairOrderId AND ISNULL([IsActive],0) = 1 AND ISNULL([IsDeleted],0) = 0 AND ISNULL([IsParent],0) = 1;
			SELECT @StatusName = [Description] FROM [dbo].[ROStatus] WITH(NOLOCK) WHERE [ROStatusId] = @RepairOrderStatus;
			SELECT @ROShippedStatusId = [ROStatusId] FROM [dbo].[ROStatus] WITH(NOLOCK) WHERE [Description] = 'Shipped';
			SELECT @ROOpenStatusId = [ROStatusId] FROM [dbo].[ROStatus] WITH(NOLOCK) WHERE [Description] = 'Open';

			IF(ISNULL(@IsFromShipping,0) = 1)
			BEGIN
				IF(ISNULL(@ROPartDataCount,0) > 0)
				BEGIN				
					--Check for multiple shipping
					SELECT @ROShippingItemCount = ISNULL(SUM(QtyShipped), 0) FROM [DBO].[RepairOrderShippingItem] WITH(NOLOCK) WHERE [RepairOrderShippingId] IN (SELECT [RepairOrderShippingId] FROM [DBO].[RepairOrderShipping] WITH(NOLOCK) WHERE [RepairOrderId] = @RepairOrderId AND ISNULL([IsActive],0) = 1 AND ISNULL([IsDeleted],0) = 0);
					IF(ISNULL(@ROShippingItemCount,0) = ISNULL(@ROPartDataCount,0))
					BEGIN 
						 UPDATE [DBO].[RepairOrder]
						 SET StatusId = @RepairOrderStatus, [Status] = @StatusName
						 WHERE RepairOrderId = @RepairOrderId;
					END
					ELSE
					BEGIN 
						SELECT @ROShippingCount = COUNT([RepairOrderShippingId]) FROM [DBO].[RepairOrderShipping] WITH(NOLOCK) WHERE [RepairOrderId] = @RepairOrderId AND ISNULL([IsActive],0) = 1 AND ISNULL([IsDeleted],0) = 0;
						
						IF(ISNULL(@ROShippingCount,0) > 0)
						BEGIN 
							--Check is all shipped or not
							IF(ISNULL(@ROPartDataCount,0) = ISNULL(@ROShippingCount,0))
							BEGIN 
								UPDATE [DBO].[RepairOrder]
								SET StatusId = @RepairOrderStatus, [Status] = @StatusName
								WHERE RepairOrderId = @RepairOrderId;
							END
						END
					END
				END
			END
			ELSE
			BEGIN
				IF(@RepairOrderStatus = @ROOpenStatusId)
				BEGIN
					UPDATE [DBO].[RepairOrder]
					SET StatusId = @RepairOrderStatus, [Status] = @StatusName
					WHERE RepairOrderId = @RepairOrderId AND [StatusId] = @ROShippedStatusId;
				END
			END

		COMMIT TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateRepairOrderStatus' 
              , @ProcedureParameters VARCHAR(3000)  = '@RepairOrderId = '''+ CAST(ISNULL(@RepairOrderId, '') AS varchar(100))													
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