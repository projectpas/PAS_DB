/*************************************************************           
 ** File:     [CreateVendorRFQPOPartRefFromBulkPO]           
 ** Author:	   
 ** Description:
 ** Purpose:         
 ** Date:       [mm/dd/yyyy]    
 ** PARAMETERS:       
 ** RETURN VALUE:     
 **************************************************************    
 ** Change History           
 **************************************************************           
 ** PR   	Date			Author					Change Description            
 ** --   	--------		-------					--------------------------------     
	1			-				-					-
	2	   13/May/2026		RAJESH GAMI				Implemented : Bulk PO For Sales Order [PN-16401]
	
--- exec CreateVendorRFQPOPartRefFromBulkPO  214
**************************************************************/     
CREATE     PROCEDURE [dbo].[CreateVendorRFQPOPartRefFromBulkPO]    
 @PurchaseOrderRFQId bigint = 0,
 @updatedByName varchar(50) = NULL
AS    
BEGIN    
 SET NOCOUNT ON;    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
      
  BEGIN TRY    
  BEGIN TRANSACTION    
  BEGIN    
   DECLARE @PriorityId bigint, @WOPartRefModuleId INT = 1, @SOPartRefModuleId INT = 3;    
   DECLARE @IsResale bit;    
   DECLARE @totalPartCount int     
   DECLARE @newPartLoopId int        
   DECLARE @PORFQPartId bigint    
   DECLARE @PORFQNumber AS VARCHAR(50) , @CurrentUTCData datetime2 = GETUTCDATE();    
   
   IF OBJECT_ID(N'tempdb..#tmpVendorParts') IS NOT NULL    
    BEGIN    
     DROP TABLE #tmpVendorParts    
    END    
    declare @NewId table (MyNewId INT)     
    CREATE TABLE #tmpVendorParts(    
       [ID] [bigint] IDENTITY(1,1) NOT NULL,    
       [NewId] [bigint] NULL    
    )    
	INSERT INTO #tmpVendorParts ([NewId])    
    SELECT VendorRFQPOPartRecordId from dbo.VendorRFQPurchaseOrderPart where VendorRFQPurchaseOrderId = @PurchaseOrderRFQId 
	
	Select @totalPartCount = COUNT(*), @newPartLoopId = MIN(ID) from #tmpVendorParts  
	
	WHILE @totalPartCount >0    
    BEGIN 
		set @PORFQPartId= (SELECT [NewId] FROM #tmpVendorParts WHERE ID = @newPartLoopId) 

		INSERT INTO [dbo].[VendorRFQPurchaseOrderPartReference]  
           ([VendorRFQPurchaseOrderId]  
           ,[VendorRFQPOPartRecordId]  
           ,[ModuleId]  
           ,[ReferenceId]  
           ,[Qty]  
           ,[RequestedQty]  
           ,[MasterCompanyId]  
           ,[CreatedBy]  
           ,[UpdatedBy]  
           ,[CreatedDate]  
           ,[UpdatedDate]  
           ,[IsActive]  
           ,[IsDeleted])  
			SELECT  
		   @PurchaseOrderRFQId  
		   ,@PORFQPartId,CASE WHEN ISNULL(SOP.SalesOrderId,0) = 0 THEN @WOPartRefModuleId ELSE @SOPartRefModuleId END,CASE WHEN ISNULL(SOP.SalesOrderId,0) = 0 THEN VRPP.WorkOrderId ELSE VRPP.SalesOrderId END   
		   ,ISNULL(VRPP.[QuantityOrdered],0)  
		   ,CASE WHEN ISNULL(SOP.SalesOrderId,0) = 0 THEN ((((ISNULL(SUM(WOM.Quantity),0))-((ISNULL(SUM(WOM.TotalReserved),0))+(ISNULL(SUM(WOM.TotalIssued),0))))+(ISNULL(SUM(WOMK.Quantity),0)))) 
		   ELSE (ISNULL(SUM(SOP.QtyOrder),0) - ISNULL(SUM(SOP.QtyReserved),0) ) END as RequestedQty  
		   , RFQP.MasterCompanyId  
		   ,@updatedByName  
		   ,@updatedByName  
		   ,@CurrentUTCData  
		   ,@CurrentUTCData  
		   ,1  
		   ,0  
		 FROM [DBO].[VendorRFQPurchaseOrderPart] VRPP WITH(NOLOCK) 
		 INNER JOIN dbo.VendorRFQPurchaseOrder RFQP with (NOLOCK) on VRPP.VendorRFQPurchaseOrderId = RFQP.VendorRFQPurchaseOrderId   
		 LEFT JOIN DBO.[WorkOrderMaterials] WOM ON WOM.WorkOrderId = VRPP.WorkOrderId AND WOM.ItemMasterId = VRPP.ItemMasterId AND WOM.ConditionCodeId = VRPP.ConditionId    
		 LEFT JOIN [DBO].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.ItemMasterId =  VRPP.ItemMasterId AND WOMK.ConditionCodeId = VRPP.ConditionId AND WOMK.WorkOrderId = WOM.WorkOrderId    
		 LEFT JOIN DBO.[SalesOrderPartV1] SOP ON SOP.SalesOrderId = VRPP.SalesOrderId AND SOP.ItemMasterId = VRPP.ItemMasterId AND SOP.ConditionId = VRPP.ConditionId    
		 WHERE VRPP.VendorRFQPOPartRecordId = @PORFQPartId AND VRPP.VendorRFQPurchaseOrderId = @PurchaseOrderRFQId  
		 GROUP BY   
		 VRPP.WorkOrderId,  
		 VRPP.[QuantityOrdered],RFQP.MasterCompanyId,VRPP.SalesOrderId,SOP.SalesOrderId

		set @totalPartCount = @totalPartCount - 1    
        set @newPartLoopId = @newPartLoopId+1
	END /** WHILE @totalPartCount >0 END ***/
 
 END /* Main END */    
  COMMIT  TRANSACTION    
 END TRY        
 BEGIN CATCH          
    
  IF @@trancount > 0    
   PRINT 'ROLLBACK'   
    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'CreateVendorRFQPOPartRefFromBulkPO'     
            , @ProcedureParameters VARCHAR(3000)  = '@PurchaseOrderRFQId = '''+ ISNULL(@PurchaseOrderRFQId, '') + ''    
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);    
 END CATCH    
END