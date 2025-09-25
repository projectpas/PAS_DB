/*************************************************************             
 ** File:   [PROCInsertVendorRFQPurchaseOrderPart]             
 ** Author:   
 ** Description: This stored procedure is used to PROCInsertVendorRFQPurchaseOrderPart
 ** Purpose:           
 ** Date:  
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1    01/12/2023   Amit Ghediya     Modify(Added Traceable & Tagged fields)
	2	 23/09/2025	  Amit Ghediya	   Update VendorRFQ refrence

**************************************************************/ 
CREATE       PROCEDURE [dbo].[PROCInsertVendorRFQPurchaseOrderPart](@TableVendorRFQPurchaseOrderPart VendorRFQPurchaseOrderPartType READONLY)  
AS  
BEGIN  
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					IF((SELECT COUNT(VendorRFQPurchaseOrderId) FROM @TableVendorRFQPurchaseOrderPart) > 0 )
					BEGIN
						DECLARE @VendorRFAPOId AS bigint
						SET @VendorRFAPOId = (SELECT TOP 1 VendorRFQPurchaseOrderId FROM @TableVendorRFQPurchaseOrderPart);
						MERGE dbo.VendorRFQPurchaseOrderPart AS TARGET
						USING @TableVendorRFQPurchaseOrderPart AS SOURCE ON (TARGET.VendorRFQPurchaseOrderId = SOURCE.VendorRFQPurchaseOrderId AND 
					  													     TARGET.VendorRFQPOPartRecordId = SOURCE.VendorRFQPOPartRecordId) 
						WHEN MATCHED 
						THEN UPDATE 
						SET TARGET.[ItemMasterId] = SOURCE.ItemMasterId,
						TARGET.[ManufacturerId] = SOURCE.ManufacturerId,
						TARGET.[PriorityId] = SOURCE.PriorityId,
						TARGET.[NeedByDate] = SOURCE.NeedByDate,
						TARGET.[PromisedDate] = SOURCE.PromisedDate,
						TARGET.[ConditionId] = SOURCE.ConditionId,
						TARGET.[QuantityOrdered] = SOURCE.QuantityOrdered,
						TARGET.[UnitCost] = SOURCE.UnitCost,
						TARGET.[ExtendedCost] = SOURCE.ExtendedCost,
						TARGET.[WorkOrderId] = SOURCE.WorkOrderId,
						TARGET.[SubWorkOrderId] = SOURCE.SubWorkOrderId,
						TARGET.[SalesOrderId] = SOURCE.SalesOrderId,
						TARGET.[ManagementStructureId] = SOURCE.ManagementStructureId,
						TARGET.[Memo] = SOURCE.Memo,
						TARGET.[UpdatedBy] = SOURCE.UpdatedBy,
						TARGET.[UpdatedDate] = SOURCE.UpdatedDate,
						TARGET.[IsActive] = SOURCE.IsActive,
						TARGET.[IsDeleted] = SOURCE.IsDeleted,
						TARGET.[UOMId] = SOURCE.UOMId,
						TARGET.[TraceableTo] = SOURCE.TraceableTo,
						TARGET.[TraceableToName] = SOURCE.TraceableToName,
					TARGET.[TraceableToType] = SOURCE.TraceableToType,
						TARGET.[TagTypeId] = SOURCE.TagTypeId,
						TARGET.[TaggedByType] = SOURCE.TaggedByType,
						TARGET.[TaggedBy] = SOURCE.TaggedBy,
						TARGET.[TaggedByName] = SOURCE.TaggedByName,
						TARGET.[TaggedByTypeName] = SOURCE.TaggedByTypeName,
						TARGET.[TagDate] = SOURCE.TagDate,
						TARGET.[IsNoQuote] = SOURCE.IsNoQuote

						WHEN NOT MATCHED BY TARGET
						THEN
							INSERT([VendorRFQPurchaseOrderId],[ItemMasterId],[PartNumber],[PartDescription],[StockType],
								   [ManufacturerId],[Manufacturer],[PriorityId],[Priority],[NeedByDate],[PromisedDate],
								   [ConditionId],[Condition],[QuantityOrdered],[UnitCost],[ExtendedCost],[WorkOrderId],
								   [WorkOrderNo],[SubWorkOrderId],[SubWorkOrderNo],[SalesOrderId],[SalesOrderNo],
								   [ManagementStructureId],[Level1],[Level2],[Level3],[Level4],[Memo],[MasterCompanyId],
								   [CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[UOMId],
								   [TraceableTo],[TraceableToName],[TraceableToType],
								   [TagTypeId]
								   ,[TaggedByType]
								   ,[TaggedBy]
								   ,[TaggedByName]
								   ,[TaggedByTypeName],[TagDate],[IsNoQuote]
								   )
							VALUES(SOURCE.VendorRFQPurchaseOrderId,SOURCE.ItemMasterId,SOURCE.PartNumber,SOURCE.PartDescription,SOURCE.StockType,
								   SOURCE.ManufacturerId,SOURCE.Manufacturer,SOURCE.PriorityId,SOURCE.Priority,SOURCE.NeedByDate,SOURCE.PromisedDate,
								   SOURCE.ConditionId,SOURCE.Condition,SOURCE.QuantityOrdered,SOURCE.UnitCost,SOURCE.ExtendedCost,SOURCE.WorkOrderId,
								   SOURCE.WorkOrderNo,SOURCE.SubWorkOrderId,SOURCE.SubWorkOrderNo,SOURCE.SalesOrderId,SOURCE.SalesOrderNo,
								   SOURCE.ManagementStructureId,SOURCE.Level1,SOURCE.Level2,SOURCE.Level3,SOURCE.Level4,SOURCE.Memo,SOURCE.MasterCompanyId,
								   SOURCE.CreatedBy,SOURCE.UpdatedBy,SOURCE.CreatedDate,SOURCE.UpdatedDate,SOURCE.IsActive,SOURCE.IsDeleted,SOURCE.UOMId,
								   SOURCE.TraceableTo,SOURCE.TraceableToName,SOURCE.TraceableToType,
								   SOURCE.TagTypeId
								   ,SOURCE.TaggedByType
								   ,SOURCE.TaggedBy
								   ,SOURCE.TaggedByName
								   ,SOURCE.TaggedByTypeName,SOURCE.TagDate,SOURCE.IsNoQuote
								   );
					
					 
				   	        EXEC PROCUpdateVendorRFQPurchaseOrderDetail @VendorRFAPOId;			
					END

					--Update VendorRFQ
							DECLARE @TotalPartsCount int = 0,
									@PartLoopId int,
									@VendorRFQPurchaseOrderId BIGINT,
									@IsFromVendorRFQ BIGINT = 0;
							DECLARE @RFQModuleId BIGINT = 0;

							SELECT @RFQModuleId = ModuleId FROM dbo.[Module] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPurchaseOrder';

							IF OBJECT_ID(N'tempdb..#tmpRFQPoPartList') IS NOT NULL    
							BEGIN    
								DROP TABLE #tmpRFQPoPartList
							END

							CREATE TABLE #tmpRFQPoPartList
							(
								ID BIGINT NOT NULL IDENTITY, 
								[VendorRFQPOPartRecordId] [bigint] NULL,
								[VendorRFQPurchaseOrderId] [bigint] NULL,
								[IsFromVendorRFQ] [bigint] NULL
							)

							--CREATE TABLE #tmpRFQPoPartList
							--(
							--	ID BIGINT NOT NULL IDENTITY, 
							--	[VendorRFQPOPartRecordId] [bigint] NULL,
							--	[VendorRFQPurchaseOrderId] [bigint] NULL,
							--	--[ItemMasterId] [bigint] NULL,
							--	--[PartNumber] [varchar](250) NULL,
							--	--[PartDescription] [varchar](max) NULL,
							--	--[StockType] [varchar](50) NULL,
							--	--[ManufacturerId] [bigint] NULL,
							--	--[Manufacturer] [varchar](250) NULL,
							--	--[PriorityId] [bigint] NULL,
							--	--[Priority] [varchar](50) NULL,
							--	--[NeedByDate] [datetime2](7) NULL,
							--	--[PromisedDate] [datetime2](7) NULL,
							--	--[ConditionId] [bigint] NULL,
							--	--[Condition] [varchar](256) NULL,
							--	--[QuantityOrdered] [int] NULL,
							--	--[UnitCost] [decimal](18, 2) NULL,
							--	--[ExtendedCost] [decimal](18, 2) NULL,
							--	--[WorkOrderId] [bigint] NULL,
							--	--[WorkOrderNo] [varchar](250) NULL,
							--	--[SubWorkOrderId] [bigint] NULL,
							--	--[SubWorkOrderNo] [varchar](250) NULL,
							--	--[SalesOrderId] [bigint] NULL,
							--	--[SalesOrderNo] [varchar](250) NULL,
							--	--[ManagementStructureId] [bigint] NULL,
							--	--[Level1] [varchar](200) NULL,
							--	--[Level2] [varchar](200) NULL,
							--	--[Level3] [varchar](200) NULL,
							--	--[Level4] [varchar](200) NULL,
							--	--[Memo] [nvarchar](max) NULL,
							--	--[MasterCompanyId] [int] NULL,
							--	--[CreatedBy] [varchar](256) NULL,
							--	--[UpdatedBy] [varchar](256) NULL,
							--	--[CreatedDate] [datetime2](7) NULL,
							--	--[UpdatedDate] [datetime2](7) NULL,
							--	--[IsActive] [bit] NULL,
							--	--[IsDeleted] [bit] NULL,
							--	--[UOMId] [bigint] NULL,
							--	--[UnitOfMeasure] [varchar](50) NULL,
							--	--[TraceableTo] [bigint] NULL,
							--	--[TraceableToName] [varchar](250) NULL,
							--	--[TraceableToType] [int] NULL,
							--	--[TagTypeId] [bigint] NULL,
							--	--[TaggedByType] [int] NULL,
							--	--[TaggedBy] [bigint] NULL,
							--	--[TaggedByName] [varchar](250) NULL,
							--	--[TaggedByTypeName] [varchar](250) NULL,
							--	--[TagDate] [datetime2](7) NULL,
							--	--[IsNoQuote] [bit] NULL,
							--	[IsFromVendorRFQ] [bigint] NULL
							--)

							INSERT INTO #tmpRFQPoPartList ([VendorRFQPOPartRecordId],[VendorRFQPurchaseOrderId]
																			,[IsFromVendorRFQ] )
							SELECT [VendorRFQPOPartRecordId],[VendorRFQPurchaseOrderId]
																			,[IsFromVendorRFQ]
						    FROM @TableVendorRFQPurchaseOrderPart;
							
							--INSERT INTO #tmpRFQPoPartList ([VendorRFQPOPartRecordId],[VendorRFQPurchaseOrderId]
							--												--,[ItemMasterId],[PartNumber] ,[PartDescription] ,
							--												--[StockType] ,[ManufacturerId] ,[Manufacturer] ,[PriorityId] ,[Priority] ,[NeedByDate] ,[PromisedDate] ,
							--												--[ConditionId] ,[Condition] ,[QuantityOrdered] ,[UnitCost] ,[ExtendedCost] ,[WorkOrderId] ,[WorkOrderNo] ,
							--												--[SubWorkOrderId] ,[SubWorkOrderNo] ,[SalesOrderId] ,[SalesOrderNo] ,[ManagementStructureId] ,[Level1] ,
							--												--[Level2] ,[Level3] ,[Level4] ,[Memo] ,[MasterCompanyId] ,[CreatedBy] ,[UpdatedBy] ,[CreatedDate] ,
							--												--[UpdatedDate] ,[IsActive] ,[IsDeleted],[UOMId],[UnitOfMeasure] ,[TraceableTo] ,[TraceableToName] ,
							--												--[TraceableToType] ,[TagTypeId] ,[TaggedByType] ,[TaggedBy] ,[TaggedByName] ,[TaggedByTypeName] ,
							--												--[TagDate] ,[IsNoQuote] ,
							--												,[IsFromVendorRFQ] )
							--SELECT [VendorRFQPOPartRecordId],[VendorRFQPurchaseOrderId]
							--												--,[ItemMasterId],[PartNumber] ,[PartDescription] ,
							--												--[StockType] ,[ManufacturerId] ,[Manufacturer] ,[PriorityId] ,[Priority] ,[NeedByDate] ,[PromisedDate] ,
							--												--[ConditionId] ,[Condition] ,[QuantityOrdered] ,[UnitCost] ,[ExtendedCost] ,[WorkOrderId] ,[WorkOrderNo] ,
							--												--[SubWorkOrderId] ,[SubWorkOrderNo] ,[SalesOrderId] ,[SalesOrderNo] ,[ManagementStructureId] ,[Level1] ,
							--												--[Level2] ,[Level3] ,[Level4] ,[Memo] ,[MasterCompanyId] ,[CreatedBy] ,[UpdatedBy] ,[CreatedDate] ,
							--												--[UpdatedDate] ,[IsActive] ,[IsDeleted],[UOMId],[UnitOfMeasure] ,[TraceableTo] ,[TraceableToName] ,
							--												--[TraceableToType] ,[TagTypeId] ,[TaggedByType] ,[TaggedBy] ,[TaggedByName] ,[TaggedByTypeName] ,
							--												--[TagDate] ,[IsNoQuote] 
							--												,[IsFromVendorRFQ]
							--FROM @TableVendorRFQPurchaseOrderPart;
							--select * from #tmpRFQPoPartList
							--SET @TotalPartsCount = (SELECT COUNT(1) FROM #tmpRFQPoPartList)
							SELECT  @PartLoopId = MAX(ID) FROM #tmpRFQPoPartList
							
							WHILE(@PartLoopId > 0)
							BEGIN 
								SELECT @VendorRFQPurchaseOrderId = VendorRFQPurchaseOrderId,@IsFromVendorRFQ = IsFromVendorRFQ
								FROM #tmpRFQPoPartList WHERE ID = @PartLoopId;
								
								IF(ISNULL(@VendorRFQPurchaseOrderId,0) > 0)
								BEGIN 
									 IF(ISNULL(@IsFromVendorRFQ,0) > 0)
									 BEGIN 
										  UPDATE dbo.[VendorRFQPart] SET ReferenceId = @VendorRFQPurchaseOrderId, ModuleId = @RFQModuleId WHERE [VendorRFQPartId] = @IsFromVendorRFQ;
									 END
								END

								SET @PartLoopId = @PartLoopId - 1;
							END
					
				END
			COMMIT  TRANSACTION
		END TRY  
		BEGIN CATCH      
			IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'PROCInsertVendorRFQPurchaseOrderPart' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL('', '') + ''													   
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