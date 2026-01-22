/*************************************************************           
 ** File:  [GetSpeedQuotePartByID]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to get SpeedQuotePartData.
 ** Purpose:         
 ** Date:   03/04/2023     
          
 ** PARAMETERS: @SpeedQuoteId BIGINT,@SpeedQuotePartId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/04/2023  Amit Ghediya    Created
     
-- EXEC GetSpeedQuotePartByID 78,195,0,0,0,1
************************************************************************/
CREATE     PROCEDURE [dbo].[GetSpeedQuotePartByID]  
  @SpeedQuoteId BIGINT,
  @SpeedQuotePartId BIGINT,
  @ItemMasterId BIGINT,
  @MasterCompanyId INT,
  @ConditionId BIGINT,
  @IsPart INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN

			IF(@IsPart = 1) -- select with partid
			BEGIN
				SELECT 
					[SpeedQuotePartId],
					[SpeedQuoteId],
					[ItemMasterId],
					[QuantityRequested],
					[ConditionId],
					[UnitSalePrice],
					[UnitCost],
					[MarginAmount],
					[MarginPercentage],
					[SalesPriceExtended],
					[UnitCostExtended],
					[MarginAmountExtended],
					[MarginPercentageExtended],
					[CreatedBy],
					[CreatedDate],
					[UpdatedBy],
					[UpdatedDate],
					[IsDeleted],
					[IsActive],
					[MasterCompanyId],
					[Notes],
					[CurrencyId],
					[PartNumber],
					[PartDescription],
					[ConditionName],
					[CurrencyName],
					[ManufacturerId],
					[Manufacturer],
					[Type],
					[TAT],
					[StatusId],
					[StatusName],
					[ItemNo],
					[Code]		
				FROM SpeedQuotePart Where SpeedQuoteId = @SpeedQuoteId AND SpeedQuotePartId = @SpeedQuotePartId;
			END
			ELSE IF(@IsPart = 0) -- for select with without partid
			BEGIN
				SELECT 
					[SpeedQuotePartId],
					[SpeedQuoteId],
					[ItemMasterId],
					[QuantityRequested],
					[ConditionId],
					[UnitSalePrice],
					[UnitCost],
					[MarginAmount],
					[MarginPercentage],
					[SalesPriceExtended],
					[UnitCostExtended],
					[MarginAmountExtended],
					[MarginPercentageExtended],
					[CreatedBy],
					[CreatedDate],
					[UpdatedBy],
					[UpdatedDate],
					[IsDeleted],
					[IsActive],
					[MasterCompanyId],
					[Notes],
					[CurrencyId],
					[PartNumber],
					[PartDescription],
					[ConditionName],
					[CurrencyName],
					[ManufacturerId],
					[Manufacturer],
					[Type],
					[TAT],
					[StatusId],
					[StatusName],
					[ItemNo],
					[Code]		
				FROM SpeedQuotePart Where SpeedQuoteId = @SpeedQuoteId AND ItemMasterId = @ItemMasterId AND ConditionId = @ConditionId; --AND MasterCompanyId = @MasterCompanyId ;
			END
			ELSE IF(@IsPart = 3) -- for delete select
			BEGIN
				SELECT 
					[SpeedQuotePartId],
					[SpeedQuoteId],
					[ItemMasterId],
					[QuantityRequested],
					[ConditionId],
					[UnitSalePrice],
					[UnitCost],
					[MarginAmount],
					[MarginPercentage],
					[SalesPriceExtended],
					[UnitCostExtended],
					[MarginAmountExtended],
					[MarginPercentageExtended],
					[CreatedBy],
					[CreatedDate],
					[UpdatedBy],
					[UpdatedDate],
					[IsDeleted],
					[IsActive],
					[MasterCompanyId],
					[Notes],
					[CurrencyId],
					[PartNumber],
					[PartDescription],
					[ConditionName],
					[CurrencyName],
					[ManufacturerId],
					[Manufacturer],
					[Type],
					[TAT],
					[StatusId],
					[StatusName],
					[ItemNo],
					[Code]		
				FROM SpeedQuotePart Where SpeedQuotePartId = @SpeedQuotePartId;
			END
		END

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetSpeedQuotePartByID' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SpeedQuoteId, '') + ''''
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