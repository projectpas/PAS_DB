/*********************           
 ** File:  [usp_SaveKITParts]           
 ** Author:  
 ** Description: This stored procedure is used to Update Kit Item Master Mapping 
 ** Purpose:         
 ** Date:     
          
 ** PARAMETERS: @PurchaseOrderId BIGINT
         
 ** RETURN VALUE:           
 **********************           
 ** Change History           
 **********************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
     
	 2   05-Sep-2023  Bhargav Saliya  Convert Date In UTC
	 3   28-02-2024   Shrey Chandegara  Update Procedure for HIstory.
     
-- EXEC RPT_PrintPurchaseOrderDataById 629
************************/
CREATE      PROCEDURE [dbo].[usp_SaveKITParts]  
@tbl_KITPartType KITPartType READONLY  
AS  
BEGIN  
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  BEGIN TRY  
  BEGIN TRANSACTION  
  DECLARE @TotalRecord BIGINT;
  DECLARE @StartCount BIGINT = 1;
  DECLARE @OldCost [decimal](18, 2) ;
  DECLARE @OldConditionId [bigint] ;
  DECLARE @OldCondition [varchar](100) ;
  DECLARE @OldQty [int] ;
  DECLARE @IsEditable [bit]=0 ;
  DECLARE @NewGeneratedId [bigint];
  DECLARE @IsNewPartAdd [bit] = 0;
  DECLARE @MasterCompanyId [int] ;
  DECLARE @KitItemMasterMappingId [bigint] ;
  DECLARE @UpdatedBy [varchar](256) ;
  DECLARE @UpdatedDate [datetime2](7);
  DECLARE @PartNumber [varchar](100) ;
  DECLARE @NewCost [decimal](18, 2) ;
  DECLARE @NewItemId [bigint] ;
  DECLARE @OldItemId [bigint] ;
  DECLARE @OldPartNumber [varchar](100) ;
  DECLARE @NewConditionId [bigint] ;
  DECLARE @NewCondition [varchar](100) ;
  DECLARE @NewQty [int] ;
  DECLARE @TempRecId BIGINT = 0;
  DECLARE @ModuleId BIGINT;
   IF OBJECT_ID(N'tempdb..#KITPartType') IS NOT NULL  
   BEGIN  
    DROP TABLE #KITPartType   
   END  
     
   CREATE TABLE #KITPartType   
   (  
    ID BIGINT NOT NULL IDENTITY,   
    [KitItemMasterMappingId] [bigint] NULL,  
    [KitId] [bigint] NULL,  
    [ItemMasterId] [bigint] NULL,  
    [ManufacturerId] [bigint] NULL,  
    [ConditionId] [bigint] NULL,  
    [UOMId] [bigint] NULL,  
    [Qty] [int] NULL,  
    [UnitCost] [decimal](18, 2) NULL,  
    [ExtendedCost] [decimal](18, 2) NULL,  
    [StocklineUnitCost] [decimal](18, 2) NULL,  
    [MasterCompanyId] [int] NULL,  
    [CreatedBy] [varchar](256) NULL,  
    [UpdatedBy] [varchar](256) NULL,  
    [CreatedDate] [datetime2](7) NULL,  
    [UpdatedDate] [datetime2](7) NULL,  
    [IsActive] [bit] NULL,  
    [IsDeleted] [bit] NULL,  
    [PartNumber] [varchar](100) NULL,  
    [PartDescription] [varchar](MAX) NULL,  
    [Manufacturer] [varchar](100) NULL,  
    [Condition] [varchar](100) NULL,  
    [UOM] [varchar](100) NULL,
	[IsEditable] [bit] NULL,
	[IsNewItem] [bit] NULL
   )  
      
   INSERT INTO #KITPartType   
   ([KitItemMasterMappingId],[KitId],[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],  
   [Qty],[UnitCost],[ExtendedCost],[StocklineUnitCost],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],  
   [PartNumber],[PartDescription],[Manufacturer],[Condition],[UOM],[IsEditable],[IsNewItem])  
   SELECT [KitItemMasterMappingId],[KitId],[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],  
   [Qty],[UnitCost],ISNULL([UnitCost],0) * ISNULL([Qty],0),[StocklineUnitCost],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],  
   [PartNumber],[PartDescription],[Manufacturer],[Condition],[UOM],[IsEditable],[IsNewItem]  
   FROM @tbl_KITPartType  

   SET @TotalRecord = (SELECT COUNT(ID) FROM #KITPartType)	
   print @TotalRecord;
   WHILE(@TotalRecord >= @StartCount)
   BEGIN
  
		print @StartCount;
		   INSERT INTO [dbo].[KitItemMasterMapping]  
			  ([KitId],[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],[Qty],[UnitCost],[StocklineUnitCost],[PartNumber],[PartDescription],[Manufacturer],  
			  [Condition],[UOM],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])  
			  SELECT [KitId],[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],[Qty],[UnitCost],[StocklineUnitCost],[PartNumber],[PartDescription],[Manufacturer],  
			  [Condition],[UOM],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted]  
			  FROM #KITPartType tmp  
			  WHERE tmp.KitItemMasterMappingId =  0 AND tmp.ID = @StartCount AND tmp.IsNewItem = 1;

			SELECT @TempRecId = KitItemMasterMappingId FROM #KITPartType WHERE ID = @StartCount;
			print @TempRecId;
			IF(ISNULL(@TempRecId , 0) > 0)
			BEGIN
				
				SELECT @OldCost = O.UnitCost,@OldConditionId = O.ConditionId,@OldCondition  = O.Condition,@OldQty = O.Qty,@OldItemId = O.ItemMasterId,@OldPartNumber = O.PartNumber FROM [DBO].[KitItemMasterMapping] O WITH(NOLOCK) WHERE O.KitItemMasterMappingId = @TempRecId;

			END
		   ---------------------------------Update Kit Item Master Mapping---------------------

		   UPDATE [dbo].[KitItemMasterMapping]  
		   SET [ItemMasterId] = t.[ItemMasterId]  
			,[ManufacturerId] = t.[ManufacturerId]  
			,[ConditionId] = t.[ConditionId]  
			,[UOMId] = t.[UOMId]  
			,[Qty] = t.[Qty]  
			,[UnitCost] = t.[UnitCost]  
			,[StocklineUnitCost] = t.[StocklineUnitCost]  
			,[PartNumber] = t.[PartNumber]  
			,[PartDescription] = t.[PartDescription]  
			,[Manufacturer] = t.[Manufacturer]  
			,[Condition] = t.[Condition]  
			,[UOM] = t.[UOM]  
			,[MasterCompanyId] = t.MasterCompanyId      
			,[UpdatedBy] = t.UpdatedBy       
			,[UpdatedDate] = GETUTCDATE()  
			,[IsActive] = t.IsActive  
			,[IsDeleted] = t.IsDeleted  
			FROM #KITPartType t  
			INNER JOIN dbo.KitItemMasterMapping kim WITH (NOLOCK) on kim.KitItemMasterMappingId = t.KitItemMasterMappingId  
			WHERE t.KitItemMasterMappingId > 0 AND t.IsEditable = 1 AND t.ID = @StartCount;  

			IF(ISNULL(@TempRecId , 0) > 0)
			BEGIN
				
				SELECT @NewCost = N.UnitCost,@NewConditionId = N.ConditionId,@NewCondition  = N.Condition,@NewQty = N.Qty,@UpdatedBy = N.UpdatedBy,@UpdatedDate  = N.UpdatedDate,@MasterCompanyId = N.MasterCompanyId,@KitItemMasterMappingId = N.KitItemMasterMappingId,@PartNumber = N.PartNumber,
				@NewItemId = N.ItemMasterId FROM [DBO].[KitItemMasterMapping] N WITH(NOLOCK) WHERE N.KitItemMasterMappingId = @TempRecId-- AND N.IsEditable = 1;

			END

		

		   -- *START*  ADD History for KitPart IN DBO.History---

		   SET @ModuleId = (SELECT ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'KitMaster');

		   IF @OldItemId <> @NewItemId --AND @IsEditable = 1
		   BEGIN
		 
				DECLARE @ReplaceContentPart NVARCHAR(MAX);

				SET @ReplaceContentPart = (SELECT [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE TemplateCode = 'UpdateItemKitPart');

				SET @ReplaceContentPart = REPLACE(@ReplaceContentPart, '##Part##', CONVERT(NVARCHAR(MAX), @OldPartNumber));

				SET @ReplaceContentPart = REPLACE(@ReplaceContentPart, '##NewPart##', CONVERT(NVARCHAR(MAX),@PartNumber));
				INSERT INTO History ([ModuleId]
			   ,[RefferenceId]
			   ,[OldValue]
			   ,[NewValue]
			   ,[HistoryText]
			   ,[FieldsName]
			   ,[MasterCompanyId]
			   ,[CreatedBy]
			   ,[CreatedDate]
			   ,[UpdatedBy]
			   ,[UpdatedDate]
			   ,[SubModuleId]
			   ,[SubRefferenceId])
				VALUES (@ModuleId,@KitItemMasterMappingId, @OldPartNumber, @PartNumber,@ReplaceContentPart ,'No', @MasterCompanyId , Null, NULL,@UpdatedBy, @UpdatedDate,NULL,@NewItemId);

		   END

		   IF @OldConditionId <> @NewConditionId --AND @IsEditable = 1
		   BEGIN
		 
				DECLARE @ReplaceContent NVARCHAR(MAX);

				SET @ReplaceContent = (SELECT [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE TemplateCode = 'UpdateItemKitCondition');

				SET @ReplaceContent = REPLACE(@ReplaceContent, '##Part##', CONVERT(NVARCHAR(MAX), @PartNumber));

				SET @ReplaceContent = REPLACE(@ReplaceContent, '##Condition##', CONVERT(NVARCHAR(MAX),@NewCondition));
				INSERT INTO History ([ModuleId]
			   ,[RefferenceId]
			   ,[OldValue]
			   ,[NewValue]
			   ,[HistoryText]
			   ,[FieldsName]
			   ,[MasterCompanyId]
			   ,[CreatedBy]
			   ,[CreatedDate]
			   ,[UpdatedBy]
			   ,[UpdatedDate]
			   ,[SubModuleId]
			   ,[SubRefferenceId])
				VALUES (@ModuleId,@KitItemMasterMappingId, @OldCondition, @NewCondition,@ReplaceContent ,'No', @MasterCompanyId , Null, NULL,@UpdatedBy, @UpdatedDate,NULL,@NewItemId);

		   END

		   IF @OldQty <> @NewQty --AND @IsEditable = 1
		   BEGIN
		    
				DECLARE @ReplaceContentForQty NVARCHAR(MAX);

				SET @ReplaceContentForQty =  (SELECT [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE TemplateCode = 'UpdateItemKitQty');
				SET @ReplaceContentForQty = REPLACE(@ReplaceContentForQty, '##Part##', CONVERT(NVARCHAR(MAX), @PartNumber));
				

				SET @ReplaceContentForQty = REPLACE(@ReplaceContentForQty, '##Qty##', CONVERT(NVARCHAR(MAX),@NewQty));
				
				INSERT INTO History ([ModuleId]
			   ,[RefferenceId]
			   ,[OldValue]
			   ,[NewValue]
			   ,[HistoryText]
			   ,[FieldsName]
			   ,[MasterCompanyId]
			   ,[CreatedBy]
			   ,[CreatedDate]
			   ,[UpdatedBy]
			   ,[UpdatedDate]
			   ,[SubModuleId]
			   ,[SubRefferenceId])
				VALUES (@ModuleId,@KitItemMasterMappingId, @OldQty, @NewQty,@ReplaceContentForQty ,'No', @MasterCompanyId , NULL, NULL,@UpdatedBy, @UpdatedDate,NULL,@NewItemId);

		   END

		   IF @OldCost <> @NewCost --AND @IsEditable = 1
		   BEGIN
		     
				DECLARE @ReplaceContentForCost NVARCHAR(MAX);

				SET @ReplaceContentForCost = (SELECT [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE TemplateCode = 'UpdateItemKitCost');
				SET @ReplaceContentForCost = REPLACE(@ReplaceContentForCost, '##Part##', CONVERT(NVARCHAR(MAX), @PartNumber));
				

				SET @ReplaceContentForCost = REPLACE(@ReplaceContentForCost, '##Cost##', CONVERT(NVARCHAR(MAX),@NewCost));
				
				INSERT INTO History ([ModuleId]
			   ,[RefferenceId]
			   ,[OldValue]
			   ,[NewValue]
			   ,[HistoryText]
			   ,[FieldsName]
			   ,[MasterCompanyId]
			   ,[CreatedBy]
			   ,[CreatedDate]
			   ,[UpdatedBy]
			   ,[UpdatedDate]
			   ,[SubModuleId]
			   ,[SubRefferenceId])
				VALUES (@ModuleId,@KitItemMasterMappingId, @OldCost, @NewCost,@ReplaceContentForCost ,'No', @MasterCompanyId , NULL, NULL,@UpdatedBy, @UpdatedDate,NULL,@NewItemId);

		   END

		   SELECT @IsNewPartAdd = im.IsNewItem  FROM KitItemMasterMapping MN WITH(NOLOCK) 
		   INNER JOIN #KITPartType im WITH(NOLOCK) on im.ItemMasterId = MN.ItemMasterId AND  im.IsNewItem = 1 AND im.ID = @StartCount

		   SELECT @NewGeneratedId = MAX(MN.KitItemMasterMappingId)  FROM KitItemMasterMapping MN WITH(NOLOCK) 
		  
		 
		   IF @NewGeneratedId <> 0 AND @NewGeneratedId > 0 AND @IsNewPartAdd = 1
		   BEGIN
		     
				  DECLARE @ReplaceContentForADD NVARCHAR(MAX);
				  DECLARE @AddCost [decimal](18, 2) ;
				  DECLARE @AddCondition [varchar](100) ;
				  DECLARE @AddQty [int] ;
				  DECLARE @AddPartNumber [varchar](100) ;
				  DECLARE @AddUpdatedBy [varchar](256) ;
				  DECLARE @AddUpdatedDate [datetime2](7);
				  DECLARE @AddMasterCompanyId [int];
				  DECLARE @AddKitItemMasterMappingId [bigint]
				  DECLARE @AddKitItemMasterId [bigint]
				  SELECT @AddCost = Ad.UnitCost,@AddCondition = Ad.Condition,@AddQty = Ad.Qty,@AddPartNumber = Ad.PartNumber,@AddUpdatedDate = Ad.UpdatedDate,@AddUpdatedBy = Ad.UpdatedBy,@AddMasterCompanyId = Ad.MasterCompanyId,@AddKitItemMasterMappingId = Ad.KitItemMasterMappingId,@AddKitItemMasterId = Ad.ItemMasterId FROM [dbo].[KitItemMasterMapping] Ad WHERE Ad.KitItemMasterMappingId = @NewGeneratedId
				SET @ReplaceContentForADD = (SELECT [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE TemplateCode = 'AddItemKit');
				SET @ReplaceContentForADD = REPLACE(@ReplaceContentForADD, '##Part##', CONVERT(NVARCHAR(MAX), @AddPartNumber));
				SET @ReplaceContentForADD = REPLACE(@ReplaceContentForADD, '##Cost##', CONVERT(NVARCHAR(MAX),@AddCost));
				SET @ReplaceContentForADD = REPLACE(@ReplaceContentForADD, '##Qty##', CONVERT(NVARCHAR(MAX),@AddQty));
				SET @ReplaceContentForADD = REPLACE(@ReplaceContentForADD, '##Condition##', CONVERT(NVARCHAR(MAX),@AddCondition));
				INSERT INTO History ([ModuleId]
           ,[RefferenceId]
           ,[OldValue]
           ,[NewValue]
           ,[HistoryText]
           ,[FieldsName]
           ,[MasterCompanyId]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[UpdatedBy]
           ,[UpdatedDate]
           ,[SubModuleId]
           ,[SubRefferenceId])

				VALUES (@ModuleId,@AddKitItemMasterMappingId, '', '',@ReplaceContentForADD ,'No', @AddMasterCompanyId , NULL, NULL, @AddUpdatedBy, @AddUpdatedDate,NULL,@AddKitItemMasterId);

		   END
		    -- *END*  ADD History for KitPart IN DBO.History---
		   SET @StartCount = @StartCount + 1;
   END

   	-- *START*  UPDATE DBO.KitMaster---
  
		   UPDATE KitMaster  
		   SET [UpdatedBy] = t.UpdatedBy       
			  ,[UpdatedDate] = GETUTCDATE()      
		   FROM #KITPartType t  
		   INNER JOIN dbo.KitMaster kim WITH (NOLOCK) on kim.[KitId] = t.[KitId]  
		   WHERE t.KitItemMasterMappingId > 0;  
  
		   DECLARE @KITID BIGINT = 0;  
		   SET @KITID = (SELECT TOP (1) [KitId] FROM #KITPartType);  
       
		   IF(@KITID > 0)  
		   BEGIN  
			UPDATE KM SET KM.[KitCost] = (SELECT ISNULL(SUM(ISNULL(KP.[ExtendedCost],0)),0) FROM #KITPartType KP   
			WHERE [KitId] = @KITID) FROM [dbo].[KitMaster] AS KM WITH (NOLOCK) WHERE [KitId] = @KITID;  
			EXEC usp_SaveKITMasterHistory @KITID
		   END

		   -- *END*  UPDATE DBO.KitMaster---
   COMMIT TRANSACTION  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
                    ROLLBACK TRAN;  
					SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
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