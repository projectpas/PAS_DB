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
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    06/02/2020   Subhash Saliya Created  
       
--EXEC [GetWorkOrderPrintPdfData] 274,258  
**************************************************************/ 


Create       PROCEDURE [dbo].[usp_SavePostKitforWOQ]
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
				[Memo] [nvarchar](max) NULL,
	            [MarkupPercentageId] [bigint] NULL,
	            [MarkupFixedPrice] [varchar](15) NULL,
	            [BillingAmount] [decimal](20, 2) NULL,
	            [BillingRate] [decimal](20, 2) NULL,
	            [HeaderMarkupId] [bigint] NULL,
	            [BillingMethodId] [int] NULL,
	            [BillingName] [varchar](50) NULL,
	            [MarkUp] [varchar](50) NULL,
				[IsInsert] [bit] NULL,
				
			)

				
			INSERT INTO #KITPartType 
			(WOQMaterialKitMappingId,WorkOrderQuoteId,WorkflowWorkOrderId,[KitId],KitNumber,[ItemMasterId],
			[Quantity],[UnitCost],[ExtendedCost],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],Memo,MarkupPercentageId,MarkupFixedPrice,BillingAmount,BillingRate,HeaderMarkupId,BillingMethodId)
			SELECT WOQMaterialKitMappingId,WorkOrderQuoteId,WorkflowWorkOrderId,[KitId],KitNumber,[ItemMasterId],
			1,[UnitCost],[ExtendedCost],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],Memo,MarkupPercentageId,MarkupFixedPrice,BillingAmount,BillingRate,HeaderMarkupId,BillingMethodId
			
			FROM @tbl_KITPartType

			print '1'
			
			update #KITPartType set IsInsert=0 where WOQMaterialKitMappingId = 0

			INSERT INTO [dbo].WorkOrderQuoteMaterialKitMapping
		    (WorkOrderQuoteId,WorkflowWorkOrderId,[KitId],KitNumber,[ItemMasterId],[Quantity],[UnitCost],[ExtendedCost],
		    [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],BillingRate,BillingAmount)
		    SELECT WorkOrderQuoteId,WorkflowWorkOrderId,tmp.KitId,KM.KitNumber,tmp.[ItemMasterId],[Quantity],[UnitCost],(UnitCost),
		    tmp.[MasterCompanyId],tmp.[CreatedBy],tmp.[UpdatedBy],tmp.[CreatedDate],tmp.[UpdatedDate],tmp.[IsActive],tmp.[IsDeleted],UnitCost,(UnitCost)
		    FROM #KITPartType tmp
			INNER JOIN KitMaster KM WITH (NOLOCK) on KM.KitId = tmp.KitId 
		    WHERE tmp.WOQMaterialKitMappingId = 0

			print '2'

			INSERT INTO [dbo].WorkOrderQuoteMaterialKit
		    (WOQMaterialKitMappingId,[KitId],[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],[Qty],[UnitCost],[PartNumber],[PartDescription],[Manufacturer],
		    [Condition],[UOM],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
		    SELECT woqkit.WOQMaterialKitMappingId,woqkit.[KitId],tmp.[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],tmp.[Qty],tmp.[UnitCost],[PartNumber],[PartDescription],[Manufacturer],
		    [Condition],[UOM],woqkit.[MasterCompanyId],woqkit.[CreatedBy],woqkit.[UpdatedBy],getdate(),getdate(),1,0
		    FROM KitItemMasterMapping  tmp
			INNER JOIN #KITPartType kim WITH (NOLOCK) on kim.KitId = tmp.KitId 
			INNER JOIN WorkOrderQuoteMaterialKitMapping woqkit WITH (NOLOCK) on woqkit.KitId = kim.KitId  and woqkit.WorkflowWorkOrderId = kim.WorkflowWorkOrderId

		    WHERE kim.WOQMaterialKitMappingId = 0 and kim.IsInsert=0
			
			print '3'
			---------------------------------Update Kit Item Master Mapping---------------------
			UPDATE kim
			SET  
				 --KitNumber = t.KitNumber
				[UnitCost] = t.UnitCost
				,[ExtendedCost] = t.ExtendedCost
				--,[MasterCompanyId] = t.MasterCompanyId    
				,[UpdatedBy] = t.UpdatedBy     
				,[UpdatedDate] = getdate()
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
				,BillingName = (case when kim.BillingMethodId = 1 then 'T&M'  when  kim.BillingMethodId = 2 then 'Actual' else '' End)
				FROM #KITPartType t
				INNER JOIN dbo.WorkOrderQuoteMaterialKitMapping kim WITH (NOLOCK) on kim.WOQMaterialKitMappingId = t.WOQMaterialKitMappingId
				LEFT JOIN dbo.[Percent] p WITH(NOLOCK) ON p.PercentId = kim.MarkupPercentageId 
			 WHERE t.WOQMaterialKitMappingId > 0;


		
				
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