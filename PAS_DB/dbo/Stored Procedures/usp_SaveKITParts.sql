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
     
-- EXEC RPT_PrintPurchaseOrderDataById 629
************************/
Create    PROCEDURE [dbo].[usp_SaveKITParts]  
@tbl_KITPartType KITPartType READONLY  
AS  
BEGIN  
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  --BEGIN TRY  
  BEGIN TRANSACTION  
  BEGIN  
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
    [UOM] [varchar](100) NULL  
   )  
      
   INSERT INTO #KITPartType   
   ([KitItemMasterMappingId],[KitId],[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],  
   [Qty],[UnitCost],[ExtendedCost],[StocklineUnitCost],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],  
   [PartNumber],[PartDescription],[Manufacturer],[Condition],[UOM])  
   SELECT [KitItemMasterMappingId],[KitId],[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],  
   [Qty],[UnitCost],ISNULL([UnitCost],0) * ISNULL([Qty],0),[StocklineUnitCost],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],  
   [PartNumber],[PartDescription],[Manufacturer],[Condition],[UOM]  
   FROM @tbl_KITPartType  
  
   INSERT INTO [dbo].[KitItemMasterMapping]  
      ([KitId],[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],[Qty],[UnitCost],[StocklineUnitCost],[PartNumber],[PartDescription],[Manufacturer],  
      [Condition],[UOM],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])  
      SELECT [KitId],[ItemMasterId],[ManufacturerId],[ConditionId],[UOMId],[Qty],[UnitCost],[StocklineUnitCost],[PartNumber],[PartDescription],[Manufacturer],  
      [Condition],[UOM],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted]  
      FROM #KITPartType tmp  
      WHERE tmp.KitItemMasterMappingId = 0  
     
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
    WHERE t.KitItemMasterMappingId > 0;  
  
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
   END  
      
   END  
   COMMIT TRANSACTION  
--  END TRY      
--  BEGIN CATCH        
--   IF @@trancount > 0  
--    PRINT 'ROLLBACK'  
--                    ROLLBACK TRAN;  
--              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-------------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
--              , @AdhocComments     VARCHAR(150)    = 'usp_SaveKITParts'   
--              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''  
--              , @ApplicationName VARCHAR(100) = 'PAS'  
-------------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
--              exec spLogException   
--                       @DatabaseName           = @DatabaseName  
--                     , @AdhocComments          = @AdhocComments  
--                     , @ProcedureParameters = @ProcedureParameters  
--                     , @ApplicationName        =  @ApplicationName  
--                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
--              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
--              RETURN(1);  
--        END CATCH       
END