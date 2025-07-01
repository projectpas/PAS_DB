/*************************************************************             
 ** File:   [GetWorkOrderPrintPdfData]             
 ** Author:   Subhash Saliya  
 ** Description: This stored procedure is used Work order Print  Details      
 ** Purpose:           
 ** Date:   12/30/2020          
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date			Author				ChangeDescription              
 ** --   --------		-------				--------------------------------            
    1    06/02/2020		Subhash Saliya		Created  
	2	 01/16/2025		Moin Bloch			Modified (Added TaskId In Type)
    3	 26 FEB 2025	RAJESH GAMI			Update the WorkOrderQuoteDetails COST
	4	 21 APR 2025	HEMANT SALIYA		Update For WOM Kit Cost is not updating
	5	 01 Jul 2025	Moin Bloch			Modified (Fixed For Billing Amount in WOQ Kit)

--EXEC [GetWorkOrderPrintPdfData] 274,258  
**************************************************************/ 

CREATE PROCEDURE [dbo].[usp_SavePostKitforWOQ]
	@tbl_KITPartType WOQMaterialKitMappingType READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
			IF OBJECT_ID(N'tempdb..#KITPartType') IS NOT NULL
			BEGIN
				DROP TABLE #KITPartType 
			END
	
			CREATE TABLE #KITPartType 
			(
				ID BIGINT NOT NULL IDENTITY, 
				[WOQMaterialKitMappingId] [bigint] NULL,
				[WorkOrderQuoteId] [bigint] NULL,
                [WorkflowWorkOrderId] [bigint] NULL,
                [KitId] [bigint] NULL,
				[KitNumber] [varchar](100) NULL,
				[ItemMasterId] [bigint] NULL,
				[Quantity] [int] NULL,
				[UnitCost] [decimal](18, 2) NULL,
				[ExtendedCost] [decimal](18, 2) NULL,
				[MasterCompanyId] [int] NULL,
				[CreatedBy] [varchar](256) NULL,
				[UpdatedBy] [varchar](256) NULL,
				[CreatedDate] [datetime2](7) NULL,
				[UpdatedDate] [datetime2](7) NULL,
				[IsActive] [bit] NULL,
				[IsDeleted] [bit] NULL,
				[Memo] [nvarchar](MAX) NULL,
	            [MarkupPercentageId] [bigint] NULL,
	            [MarkupFixedPrice] [varchar](15) NULL,
	            [BillingAmount] [decimal](20, 2) NULL,
	            [BillingRate] [decimal](20, 2) NULL,
	            [HeaderMarkupId] [bigint] NULL,
	            [BillingMethodId] [int] NULL,
	            [BillingName] [varchar](50) NULL,
	            [MarkUp] [varchar](50) NULL,
				[IsInsert] [bit] NULL,
				[TaskId] [bigint] NULL
			)

				
			INSERT INTO #KITPartType 
			(WOQMaterialKitMappingId,WorkOrderQuoteId,WorkflowWorkOrderId,[KitId],KitNumber,[ItemMasterId],
			[Quantity],[UnitCost],[ExtendedCost],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],Memo,MarkupPercentageId,MarkupFixedPrice,BillingAmount,BillingRate,HeaderMarkupId,BillingMethodId,[TaskId])
			SELECT WOQMaterialKitMappingId,WorkOrderQuoteId,WorkflowWorkOrderId,[KitId],KitNumber,[ItemMasterId],
			1,[UnitCost],[ExtendedCost],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],Memo,MarkupPercentageId,MarkupFixedPrice,BillingAmount,BillingRate,HeaderMarkupId,BillingMethodId,[TaskId]			
			FROM @tbl_KITPartType
		
			UPDATE #KITPartType SET IsInsert=0 WHERE WOQMaterialKitMappingId = 0

			INSERT INTO [dbo].[WorkOrderQuoteMaterialKitMapping]
		    (WorkOrderQuoteId,WorkflowWorkOrderId,[KitId],KitNumber,[ItemMasterId],[Quantity],[UnitCost],[ExtendedCost],
		    [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[BillingRate],[BillingAmount],[TaskId])
		    SELECT WorkOrderQuoteId,WorkflowWorkOrderId,tmp.KitId,KM.KitNumber,tmp.[ItemMasterId],[Quantity],[UnitCost],(UnitCost),
		    tmp.[MasterCompanyId],tmp.[CreatedBy],tmp.[UpdatedBy],tmp.[CreatedDate],tmp.[UpdatedDate],tmp.[IsActive],tmp.[IsDeleted],[UnitCost],tmp.[BillingAmount],tmp.[TaskId]   --(UnitCost),
		    FROM #KITPartType tmp
			INNER JOIN [dbo].[KitMaster] KM WITH (NOLOCK) ON KM.KitId = tmp.KitId 
		    WHERE tmp.WOQMaterialKitMappingId = 0

			INSERT INTO [dbo].[WorkOrderQuoteMaterialKit]
		    (WOQMaterialKitMappingId,[KitId],[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],[Qty],[UnitCost],[PartNumber],[PartDescription],[Manufacturer],
		    [Condition],[UOM],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
		    SELECT woqkit.WOQMaterialKitMappingId,woqkit.[KitId],tmp.[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],tmp.[Qty],tmp.[UnitCost],[PartNumber],[PartDescription],[Manufacturer],
		    [Condition],[UOM],woqkit.[MasterCompanyId],woqkit.[CreatedBy],woqkit.[UpdatedBy],GETUTCDATE(),GETUTCDATE(),1,0
		    FROM [dbo].[KitItemMasterMapping]  tmp WITH (NOLOCK)
			INNER JOIN #KITPartType kim WITH (NOLOCK) ON kim.KitId = tmp.KitId 
			INNER JOIN [dbo].[WorkOrderQuoteMaterialKitMapping] woqkit WITH (NOLOCK) ON woqkit.KitId = kim.KitId  and woqkit.WorkflowWorkOrderId = kim.WorkflowWorkOrderId

		    WHERE kim.WOQMaterialKitMappingId = 0 and kim.IsInsert=0
			
			---------------------------------Update Kit Item Master Mapping---------------------
			UPDATE kim
			SET  [UnitCost] = t.UnitCost
				,[ExtendedCost] = t.ExtendedCost				
				,[UpdatedBy] = t.UpdatedBy     
				,[UpdatedDate] = GETUTCDATE()
				,[IsActive] = t.IsActive
				,[IsDeleted] = t.IsDeleted
				,Memo=t.Memo
				,MarkupPercentageId=t.MarkupPercentageId
				,MarkupFixedPrice= t.MarkupFixedPrice
				,BillingAmount =t.BillingAmount
				,BillingRate= t.BillingRate
				,HeaderMarkupId= t.HeaderMarkupId
				,BillingMethodId= t.BillingMethodId
				,MarkUp = p.PercentValue
				,BillingName = (CASE WHEN kim.BillingMethodId = 1 THEN 'T&M'  WHEN  kim.BillingMethodId = 2 THEN 'Actual' ELSE '' END)
				FROM #KITPartType t
				INNER JOIN [dbo].[WorkOrderQuoteMaterialKitMapping] kim WITH (NOLOCK) ON kim.WOQMaterialKitMappingId = t.WOQMaterialKitMappingId
				LEFT JOIN [dbo].[Percent] p WITH(NOLOCK) ON p.PercentId = kim.MarkupPercentageId 
			 WHERE t.WOQMaterialKitMappingId > 0;

			/********************** Update the WorkOrderQuoteDetails COST **************************/ 			
			IF((SELECT TOP 1 IsUpdateQuoteDetail FROM @tbl_KITPartType) =1)
			BEGIN			
					DECLARE @TotalMaterialCost decimal(18,2)=0, @TotalKitCost decimal(18,2)=0,@WorkOrderWorkflowId BIGINT = (SELECT TOP 1 WorkflowWorkOrderId FROM @tbl_KITPartType), @WorkOrderQuoteDetailsId BIGINT =0,@TotalAmount decimal(18,2)=0 ;
					DECLARE @WorkOrderQuoteId BIGINT = (SELECT TOP 1 WorkOrderQuoteId FROM @tbl_KITPartType), @MasterCompanyId BIGINT = (SELECT TOP 1 MasterCompanyId FROM @tbl_KITPartType)
					DECLARE @IsUpdateQuoteDetail BIGINT = (SELECT TOP 1 IsUpdateQuoteDetail FROM @tbl_KITPartType);
					DECLARE @TotalMaterialBilling decimal(18,2)=0, @TotalKitBilling decimal(18,2)=0, @TotalBilling decimal(18,2)=0

					SET @WorkOrderQuoteDetailsId = (SELECT TOP 1  WOQD.WorkOrderQuoteDetailsId
					FROM dbo.WorkOrderQuoteDetails WOQD WITH(NOLOCK) 
						JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOQD.WorkflowWorkOrderId = WOWF.WorkFlowWorkOrderId AND WOQD.WOPartNoId = WOWF.WorkOrderPartNoId
					WHERE WOQD.WorkflowWorkOrderId = @WorkOrderWorkflowId AND WOQD.IsVersionIncrease = 0 AND WOWF.WorkOrderPartNoId = WOQD.WOPartNoId AND WOQD.WorkOrderQuoteId= @WorkOrderQuoteId AND WOQD.MasterCompanyId = @MasterCompanyId)
					
					SET @TotalMaterialBilling = (SELECT SUM(ISNULL(BillingAmount,0)) FROM DBO.WorkOrderQuoteMaterial WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId AND ISNULL(IsDeleted,0) = 0 AND MasterCompanyId = @MasterCompanyId)
					SET @TotalKitBilling = (SELECT SUM(ISNULL(BillingAmount,0)) FROM [dbo].[WorkOrderQuoteMaterialKitMapping] kim WITH (NOLOCK) WHERE WorkflowWorkOrderId = @WorkOrderWorkflowId AND WorkOrderQuoteId = @WorkOrderQuoteId AND ISNULL(IsDeleted,0) = 0 AND MasterCompanyId = @MasterCompanyId)
					SET @TotalBilling = ISNULL(@TotalMaterialBilling,0.00) +  ISNULL(@TotalKitBilling,0.00)

					SET @TotalMaterialCost = (SELECT SUM(ISNULL(BillingAmount,0)) FROM DBO.WorkOrderQuoteMaterial WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId AND ISNULL(IsDeleted,0) = 0 AND MasterCompanyId = @MasterCompanyId)
					SET @TotalKitCost = (SELECT SUM(ISNULL(BillingAmount,0)) FROM [dbo].[WorkOrderQuoteMaterialKitMapping] kim WITH (NOLOCK) WHERE WorkflowWorkOrderId = @WorkOrderWorkflowId AND WorkOrderQuoteId = @WorkOrderQuoteId AND ISNULL(IsDeleted,0) = 0 AND MasterCompanyId = @MasterCompanyId)
					SET @TotalAmount = ISNULL(@TotalMaterialCost,0.00) +  ISNULL(@TotalKitCost,0.00)
				
					UPDATE  dbo.WorkOrderQuoteDetails SET MaterialFlatBillingAmount=@TotalBilling, MaterialCost = @TotalAmount ,MaterialBilling=@TotalBilling,MaterialRevenue=@TotalBilling WHERE  WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;
			END
			
			END
			COMMIT TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_SaveKITParts' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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