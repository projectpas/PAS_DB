﻿/*************************************************************               
--EXEC GetReceivingReconciliationDetailsById 27,0,'RPO'
************************************************************************/
CREATE   PROCEDURE [dbo].[GetReceivingReconciliationDetailsById]
@ReceivingReconciliationId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	            DECLARE @NONStockModuleID INT = 11;
	            DECLARE @ModuleID INT = 2;
				DECLARE @AssetModuleID varchar(500) ='42,43'

				SELECT   [ReceivingReconciliationDetailId]
					 ,JBH.[ReceivingReconciliationId]
					 ,[StocklineId]
					 ,[StocklineNumber]
					 ,[ItemMasterId]
					 ,[PartNumber]
					 ,[PartDescription]
					 ,[SerialNumber]
					 ,[POReference]
					 ,[POQtyOrder]
					 ,[ReceivedQty]
					 ,[POUnitCost]
					 ,[POExtCost]
					 ,[InvoicedQty]
					 ,[InvoicedUnitCost]
					 ,[InvoicedExtCost]
					 ,[AdjQty]
					 ,[AdjUnitCost]
					 ,[AdjExtCost]
					 ,[APNumber]
					 ,[PurchaseOrderId]
					 ,[PurchaseOrderPartRecordId]
					 ,[IsManual]
					 ,[PackagingId]
					 ,[Description]
					 ,[GlAccountId]
					 ,[Type]
					 ,[StockType]
					 ,[RemainingRRQty]
					 ,CASE WHEN UPPER(JBD.StockType)= 'STOCK' then UPPER(MSD.Level1Name) 
						   WHEN UPPER(JBD.StockType)= 'NONSTOCK' then UPPER(NMSD.Level1Name) 
						   WHEN UPPER(JBD.StockType)= 'ASSET' then UPPER(AMSD.Level1Name) Else '' END  AS level1
					 ,CASE WHEN UPPER(JBD.StockType)= 'STOCK' then UPPER(MSD.Level2Name) 
						   WHEN UPPER(JBD.StockType)= 'NONSTOCK' then UPPER(NMSD.Level2Name) 
						   WHEN UPPER(JBD.StockType)= 'ASSET' then UPPER(AMSD.Level2Name) Else '' END  AS level2
					 ,CASE WHEN UPPER(JBD.StockType)= 'STOCK' then UPPER(MSD.Level3Name) 
						   WHEN UPPER(JBD.StockType)= 'NONSTOCK' then UPPER(NMSD.Level3Name) 
						   WHEN UPPER(JBD.StockType)= 'ASSET' then UPPER(AMSD.Level3Name) Else '' END  AS level3
					 ,CASE WHEN UPPER(JBD.StockType)= 'STOCK' then UPPER(MSD.Level4Name) 
						   WHEN UPPER(JBD.StockType)= 'NONSTOCK' then UPPER(NMSD.Level4Name) 
						   WHEN UPPER(JBD.StockType)= 'ASSET' then UPPER(AMSD.Level4Name) Else '' END  AS level4
					,CASE WHEN UPPER(JBD.StockType)= 'STOCK' then UPPER(MSD.Level5Name) 
						   WHEN UPPER(JBD.StockType)= 'NONSTOCK' then UPPER(NMSD.Level5Name) 
						   WHEN UPPER(JBD.StockType)= 'ASSET' then UPPER(AMSD.Level5Name) Else '' END  AS level5
					 ,CASE WHEN UPPER(JBD.StockType)= 'STOCK' then UPPER(MSD.Level6Name) 
						   WHEN UPPER(JBD.StockType)= 'NONSTOCK' then UPPER(NMSD.Level6Name) 
						   WHEN UPPER(JBD.StockType)= 'ASSET' then UPPER(AMSD.Level6Name) Else '' END  AS level6
					,CASE WHEN UPPER(JBD.StockType)= 'STOCK' then UPPER(MSD.Level7Name) 
						   WHEN UPPER(JBD.StockType)= 'NONSTOCK' then UPPER(NMSD.Level7Name) 
						   WHEN UPPER(JBD.StockType)= 'ASSET' then UPPER(AMSD.Level7Name) Else '' END  AS level7
					 ,CASE WHEN UPPER(JBD.StockType)= 'STOCK' then UPPER(MSD.Level8Name) 
						   WHEN UPPER(JBD.StockType)= 'NONSTOCK' then UPPER(NMSD.Level8Name) 
						   WHEN UPPER(JBD.StockType)= 'ASSET' then UPPER(AMSD.Level8Name) Else '' END  AS level8
					,CASE WHEN UPPER(JBD.StockType)= 'STOCK' then UPPER(MSD.Level9Name) 
						   WHEN UPPER(JBD.StockType)= 'NONSTOCK' then UPPER(NMSD.Level9Name) 
						   WHEN UPPER(JBD.StockType)= 'ASSET' then UPPER(AMSD.Level9Name) Else '' END  AS level9
					 ,CASE WHEN UPPER(JBD.StockType)= 'STOCK' then UPPER(MSD.Level10Name) 
						   WHEN UPPER(JBD.StockType)= 'NONSTOCK' then UPPER(NMSD.Level10Name) 
						   WHEN UPPER(JBD.StockType)= 'ASSET' then UPPER(AMSD.Level10Name) Else '' END  AS level10
				 FROM [dbo].[ReceivingReconciliationDetails] JBD WITH(NOLOCK)
					 Inner JOIN ReceivingReconciliationHeader JBH WITH(NOLOCK) ON JBD.ReceivingReconciliationId=JBH.ReceivingReconciliationId
					 LEFT JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = JBD.StockLineId and UPPER(JBD.StockType)= 'STOCK'
					 LEFT JOIN dbo.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID
					 LEFT JOIN dbo.NonStocklineManagementStructureDetails NMSD WITH (NOLOCK) ON NMSD.ModuleID = @NONStockModuleID AND NMSD.ReferenceID = JBD.StockLineId and UPPER(JBD.StockType)= 'NONSTOCK'
					 LEFT JOIN dbo.EntityStructureSetup NES ON NES.EntityStructureId=NMSD.EntityMSID
					 LEFT JOIN dbo.AssetManagementStructureDetails AMSD WITH (NOLOCK) ON AMSD.ModuleID IN (SELECT Item FROM DBO.SPLITSTRING(@AssetModuleID,',')) AND AMSD.ReferenceID = JBD.StockLineId and UPPER(JBD.StockType)= 'ASSET'
					 LEFT JOIN dbo.EntityStructureSetup AES ON AES.EntityStructureId=AMSD.EntityMSID
				 WHERE JBD.ReceivingReconciliationId =@ReceivingReconciliationId
    END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReceivingReconciliationDetailsById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceivingReconciliationId, '') + ''
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