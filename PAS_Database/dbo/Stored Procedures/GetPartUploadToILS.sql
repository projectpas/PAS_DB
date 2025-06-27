/*************************************************************           
 ** File: GetPartUploadToILS
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used All part for ils upload.
 ** Purpose:         
 ** Date:   25/06/2025        
          
 ** PARAMETERS: @MasterCompanyId bigint      
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		   Change Description            
 ** --   --------     -------		   -------------------------------          
    1    25/06/2025   Amit Ghediya     Created
    
 EXEC GetPartUploadToILS 1

**************************************************************/ 
    
CREATE   PROCEDURE [dbo].[GetPartUploadToILS]       
	@MasterCompanyId BIGINT
AS    
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	SET NOCOUNT ON  
	BEGIN TRY

			DECLARE @Condition_Code VARCHAR(100) = 'AR,NE,NS,OH,SVC',
					@NHA_MappingType INT = 1;

			SELECT  TOP 2
				1 AS ITEMNUMBER,
				'' AS 'COMPANYID',
				IM.Partnumber AS 'PARTNUMBER',
				IM1.partnumber AS 'ALTERNATEPARTNUMBER',
				STK.Condition AS CONDITIONCD,
				'Y' AS ILSLISTCD,
				0 AS PARTVALUE,
				IM.PartDescription AS 'DESCRIPTION',
				--IM.PartAlternatePartId,
				'' AS CAGE,
				STK.Quantity AS QUANTITY,
				STK.UnitOfMeasure AS UNITOFMEASURE,
				STK.UnitCost AS PRICE,
				'' AS PARTCATEGORY,
				'' AS 'CONTROL',
				'' AS EXCHANGESEL
				--STK.Condition,
				--STK.ConditionId
			FROM [dbo].[Stockline] STK WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = STK.ItemMasterId
			LEFT JOIN [dbo].[Nha_Tla_Alt_Equ_ItemMapping] TLA WITH(NOLOCK) ON STK.ItemMasterId = TLA.ItemMasterId AND TLA.MappingType = @NHA_MappingType
			INNER JOIN [dbo].[ItemMaster] IM1 WITH(NOLOCK) ON IM1.ItemMasterId = TLA.MappingItemMasterId
			INNER JOIN [dbo].[StocklineSettings] STKS WITH(NOLOCK) ON  STKs.SiteId = STK.SiteId 
				  AND STK.WarehouseId = STKS.WarehouseId 
				  AND STK.LocationId = STKS.LocationId 
				  AND STK.ShelfId = STKS.ShelfId
				  AND STK.BinId = STKS.BinId
				  AND STKS.MasterCompanyId = @MasterCompanyId
			INNER JOIN [dbo].[Condition] CON WITH(NOLOCK) ON CON.ConditionId = STK.ConditionId
			WHERE STK.MasterCompanyId = @MasterCompanyId AND CON.[Description] IN(SELECT item FROM SplitString(@Condition_Code,','))
			ORDER BY STK.CreatedDate DESC
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0				
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetPartUploadToILS' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@MasterCompanyId AS varchar(MAX)) ,'') +''
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