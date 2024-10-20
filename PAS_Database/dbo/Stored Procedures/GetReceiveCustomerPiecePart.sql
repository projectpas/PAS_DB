﻿/*************************************************************           
 ** File:   [GetReceiveCustomerPiecePartt]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to get Receive Customer Piece Part
 ** Purpose:         
 ** Date:   02/09/2024     
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** -----------------------------------------------------------          
    1    02/09/2024   Moin Bloch    Created
	2    27/09/2024   Moin Bloch    Added WOInspectionId   
	     
    EXEC GetReceiveCustomerPiecePart 1831,109,1
************************************************************************/    
CREATE   PROCEDURE [dbo].[GetReceiveCustomerPiecePart]  
@ReceivingCustomerWorkId [bigint] NULL,
@CustomerId [bigint] NULL,
@MasterCompanyId [int] NULL 
AS    
BEGIN    
 SET NOCOUNT ON;    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  	
 BEGIN TRY 
	
		DECLARE @ReceivingNumber VARCHAR(MAX) = '';
	    DECLARE @ReceivingNumbers VARCHAR(MAX) = '';
		DECLARE @Finalstring VARCHAR(MAX) = '';
		DECLARE @FinalReceivingNumber VARCHAR(MAX) = '';
		
	    DECLARE @RCManagementStructureModuleId BIGINT;
					
		SELECT @RCManagementStructureModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'RecevingCustomer';				
		
		SELECT @ReceivingNumber = [ReceivingNumber] FROM [dbo].[ReceivingCustomerWork] WITH(NOLOCK) WHERE [ReceivingCustomerWorkId] = @ReceivingCustomerWorkId;
		
		SELECT @ReceivingNumbers = STRING_AGG([ReceivingNumber],',') FROM [dbo].[ReceivingCustomerWork] WITH(NOLOCK) WHERE [ReceivingNumber] = @ReceivingNumber;
		
		SELECT @finalstring = @finalstring + value + ',' FROM STRING_SPLIT(@ReceivingNumbers,',') GROUP BY value
		
		SELECT @FinalReceivingNumber = SUBSTRING(@finalstring,0,LEN(@finalstring));
		
		SELECT RC.[ReceivingCustomerWorkId],RC.[EmployeeId],SL.[CustomerId],RC.[ReceivingNumber],RC.[CustomerContactId],SL.[ItemMasterId],RC.[RevisePartId],
		        SL.[IsSerialized],SL.[SerialNumber],SL.[Quantity],SL.[ConditionId],SL.[SiteId],SL.[WarehouseId],SL.[LocationId],SL.[Shelfid],SL.[BinId],
				RC.[OwnerTypeId],RC.[Owner],SL.[IsCustomerStock],RC.[TraceableToTypeId],RC.[TraceableTo],RC.[ObtainFromTypeId],RC.[ObtainFrom],RC.[IsMFGDate],
				RC.[MFGDate],RC.[MFGTrace],RC.[MFGLotNo],RC.[IsExpDate],RC.[ExpDate],RC.[IsTimeLife],RC.[TagDate],RC.[TagType],RC.[TagTypeIds],
				RC.[TimeLifeDate],RC.[TimeLifeOrigin],RC.[Memo],RC.[PartCertificationNumber],RC.[ManagementStructureId],
				SL.[StockLineId],RC.[WorkOrderId],SL.[MasterCompanyId],SL.[CreatedBy],SL.[UpdatedBy],SL.[CreatedDate],SL.[UpdatedDate],SL.[IsActive],
				SL.[IsDeleted],
				ISNULL(RC.[IsSkipSerialNo],0) IsSkipSerialNo,
				ISNULL(RC.[IsSkipTimeLife],0) IsSkipTimeLife,
				ISNULL(RC.[IsSkipShippingReference],0) IsSkipShippingReference,
				RC.[Reference],RC.[CertifiedBy],RC.[ReceivedDate],RC.[CustReqDate],
				RC.[Level1],RC.[Level2],RC.[Level3],RC.[Level4],RC.[EmployeeName],RC.[CustomerName],RC.[WorkScopeId],RC.[CustomerCode],RC.[ManufacturerName],
				RC.[InspectedById],RC.[CertifiedDate],RC.[ObtainFromName],RC.[OwnerName],RC.[TraceableToName],IM.[PartNumber],IM.[PartDescription],RC.[WorkScope],RC.[Condition],
				SL.[Site],SL.[Warehouse],SL.[Location],SL.[Shelf],SL.[Bin],RC.[InspectedBy],RC.[InspectedDate],RC.[TaggedById],RC.[TaggedBy],RC.[ACTailNum],
				RC.[TaggedByType],RC.[TaggedByTypeName],RC.[CertifiedById],RC.[CertifiedTypeId],RC.[CertifiedType],RC.[CertTypeId],RC.[CertType],
				RC.[RemovalReasonId],RC.[RemovalReasons],RC.[RemovalReasonsMemo],RC.[ExchangeSalesOrderId],RC.[CustReqTagTypeId],RC.[CustReqTagType],
				RC.[CustReqCertTypeId],RC.[CustReqCertType],RC.[RepairOrderPartRecordId],RC.[IsExchangeBatchEntry],
				SL.[StockLineNumber],SL.[EngineSerialNumber],SL.[ShippingViaId],SL.[ShippingAccount],SL.[ShippingReference],SL.[PurchaseUnitOfMeasureId],
				SL.[GLAccountId],SL.[UnitCost],(ISNULL(RC.[Quantity],0) * (ISNULL(SL.[UnitCost],0))) AS ExtendedCost,SL.[ManufacturingBatchNumber],
				SL.[ManufacturerId],SL.[TimeLifeDetailsNotProvided],
				TL.[TimeLifeCyclesId],TL.[CyclesRemaining],TL.[CyclesSinceNew],TL.[CyclesSinceOVH],TL.[CyclesSinceInspection],TL.[CyclesSinceRepair]
               ,TL.[TimeRemaining],TL.[TimeSinceNew],TL.[TimeSinceOVH],TL.[TimeSinceInspection],TL.[TimeSinceRepair],TL.[LastSinceNew]
               ,TL.[LastSinceOVH],TL.[LastSinceInspection],TL.[DetailsNotProvided]
			   ,MS.[LastMSLevel],MS.[AllMSlevels]			  
			   ,ISNULL(WI.WOInspectionId,0) WOInspectionId
          FROM [dbo].[ReceivingCustomerWork] RC WITH(NOLOCK) 
		  INNER JOIN [dbo].[ItemMaster] IM  WITH(NOLOCK) ON RC.[ItemMasterId] = IM.[ItemMasterId]
		  INNER JOIN [dbo].[WorkOrderManagementStructureDetails] MS WITH (NOLOCK) ON RC.[ReceivingCustomerWorkId] = MS.[ReferenceID] AND MS.[ModuleID] = @RCManagementStructureModuleId  		  
		  INNER JOIN [dbo].[Stockline] SL  WITH(NOLOCK) ON RC.[StockLineId] = SL.[StockLineId] AND [IsParent] = 1
		   LEFT JOIN [dbo].[TimeLife] TL  WITH(NOLOCK) ON TL.[StockLineId] = SL.[StockLineId] 
		   LEFT JOIN [dbo].[WOInspectionChecklist] WI WITH(NOLOCK) ON RC.[ReceivingCustomerWorkId] = WI.[ReceivingCustomerWorkId]
		  WHERE RC.[MasterCompanyId] = @MasterCompanyId AND RC.[CustomerId] = @CustomerId AND RC.[ReceivingNumber] IN (@FinalReceivingNumber);		   			    
 END TRY        
 BEGIN CATCH  
  IF @@trancount > 0    
     DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetReceiveCustomerPiecePart'     
			, @ProcedureParameters VARCHAR(3000) = '@ReceivingCustomerWorkId = ''' + CAST(ISNULL(@ReceivingCustomerWorkId, '') AS VARCHAR(100))  
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