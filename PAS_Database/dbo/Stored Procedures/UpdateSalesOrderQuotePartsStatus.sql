/*************************************************************           
 ** File:   [UpdateSalesOrderQuotePartsStatus]           
 ** Author:   EKTA CHANDEGRA
 ** Description: This stored procedure is used to UpdateSalesOrderQuotePartsStatus
 ** Purpose:         
 ** Date: 04/03/2025      
          
 ** PARAMETERS: @SalesOrderQuotePartId BIGINT, @SalesOrderQuotePartStatus INT, @UpdatedBy VARCHAR(256)

 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 ******************************************x********************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/03/2025	 EKTA CHANDEGRA	 Created  

--  exec dbo.UpdateSalesOrderQuotePartsStatus @SalesOrderQuotePartId=3377,@SalesOrderQuotePartStatus=3,@UpdatedBy=N'EKTA CHANDEGRA'
************************************************************************/
CREATE   PROCEDURE [dbo].[UpdateSalesOrderQuotePartsStatus]
    @SalesOrderQuotePartId BIGINT,
    @SalesOrderQuotePartStatus INT,
    @UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		DECLARE @ItemMasterId BIGINT;
		DECLARE @ConditionId BIGINT;
		DECLARE @Result BIT;
		SET @Result = 0;

		-- Retrieve the first sales order quote part
		SELECT TOP 1 @ItemMasterId = sop.ItemMasterId,
					 @ConditionId = sop.ConditionId
		FROM [dbo].[SalesOrderQuotePartV1] sop WITH(NOLOCK)
		WHERE ISNULL(sop.IsActive,0) = 1 
		  AND ISNULL(sop.IsDeleted,0) = 0 
		  AND sop.SalesOrderQuotePartId = @SalesOrderQuotePartId;

		IF @ItemMasterId IS NOT NULL AND @ConditionId IS NOT NULL
		BEGIN
			-- Update all matching sales order quote parts
			UPDATE [dbo].[SalesOrderQuotePartV1]
			SET StatusId = @SalesOrderQuotePartStatus,
				UpdatedBy = @UpdatedBy,
				UpdatedDate = GETUTCDATE()
			WHERE ISNULL(IsActive,0) = 1 
			  AND ISNULL(IsDeleted,0) = 0
			  AND ItemMasterId = @ItemMasterId
			  AND ConditionId = @ConditionId;
			
			IF @@ROWCOUNT > 0
			BEGIN
				SET @Result = 1;
			END
		END
		SELECT @Result AS 'Result';
	END TRY
	BEGIN CATCH
	DECLARE @ErrorLogID INT
	,@DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	,@AdhocComments VARCHAR(150) = 'UpdateSalesOrderQuotePartsStatus'
	, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SalesOrderQuotePartId, '') as Varchar(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@SalesOrderQuotePartStatus, '') as Varchar(100))+		
											  '@Parameter3 = '''+  CAST(ISNULL(@UpdatedBy, '') as Varchar(100))		
	,@ApplicationName VARCHAR(100) = 'PAS'

-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	EXEC spLogException @DatabaseName = @DatabaseName
	,@AdhocComments = @AdhocComments
	,@ProcedureParameters = @ProcedureParameters
	,@ApplicationName = @ApplicationName
	,@ErrorLogID = @ErrorLogID OUTPUT;

	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

	RETURN (1);
	END CATCH
END