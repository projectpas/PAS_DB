/*************************************************************
 ** File:  [USP_InsertOrUpdateItemMasterPurchaseSales] 
 ** Author:   Ekta Chandegra
 ** Description: This stored procedure is used to Insert or Update UnitSalePrice And UnitPurchasePrice
 ** Purpose:
 ** Date:  10/01/2024
 ** PARAMETERS: 
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    10/01/2024		  Ekta Chandegra		  Created
    2    09/02/2024		  Ekta Chandegra		  Added table type 
    3    16/02/2024		  Ekta Chandegra		  Update purchase price also 
	4    19/02/2024		  Ekta Chandegra		  Set Flat price amount and sales price 
	5	 20/02/2024		  Ekta Chandegra		  Set markup amount and markup percentage empty
	6	 23/02/2024		  Ekta Chandegra		  Set purchase disc amount and purchase disc percentage empty and set unit purchase price as vendor list price

declare @p1 dbo.ItemMasterPurchaseSalesType
insert into @p1 values(24,1,1,120.00,250.00)
insert into @p1 values(20751,7,1,340.00,250.00)

exec [dbo].[USP_InsertOrUpdateItemMasterPurchaseSales] @tbl_ItemMasterPurchaseSalesType=@p1


**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_InsertOrUpdateItemMasterPurchaseSales]      
(
    @tbl_ItemMasterPurchaseSalesType ItemMasterPurchaseSalesType READONLY
)
AS    
BEGIN    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON   
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

				DECLARE @MainPartLoopID AS INT;
				DECLARE @LoopID AS INT;
				DECLARE @CurrentIndex BIGINT;

					IF OBJECT_ID(N'tempdb..#ItemMasterPurchaseSalesType') IS NOT NULL
				BEGIN
				DROP TABLE #ItemMasterPurchaseSalesType 
				END
				
				CREATE TABLE #ItemMasterPurchaseSalesType
				(
				    [ID] BIGINT NOT NULL IDENTITY,
					[ItemMasterId] [bigint] NULL,
					[ConditionId] [bigint] NULL,
					[MasterCompanyId] [bigint] NULL,
					[UnitSalePrice] [decimal](18, 2) NULL,
					[UnitPurchasePrice] [decimal](18, 2) NULL
				)

				INSERT INTO #ItemMasterPurchaseSalesType
				(
					[ItemMasterId] ,
					[ConditionId] ,
					[MasterCompanyId] ,
					[UnitSalePrice] ,
					[UnitPurchasePrice]
				)
				SELECT [ItemMasterId] ,[ConditionId] ,[MasterCompanyId] ,[UnitSalePrice] ,
					[UnitPurchasePrice]  FROM  @tbl_ItemMasterPurchaseSalesType;

				SELECT @MainPartLoopID = MAX(ID) FROM #ItemMasterPurchaseSalesType;

				WHILE (@MainPartLoopID > 0)
				BEGIN
					DECLARE @ItemMasterId BIGINT;
					DECLARE @ConditionId BIGINT;
					DECLARE @MasterCompanyId BIGINT;
					DECLARE @UnitSalePrice DECIMAL(18,2);
					DECLARE @UnitPurchasePrice DECIMAL(18,2);

                SELECT @ItemMasterId = ItemMasterId ,
					   @ConditionId = ConditionId ,
					   @MasterCompanyId = MasterCompanyId,
					   @UnitSalePrice = UnitSalePrice,
					   @UnitPurchasePrice = UnitPurchasePrice
                FROM #ItemMasterPurchaseSalesType
                WHERE ID = @MainPartLoopID;

				 IF OBJECT_ID(N'tempdb..#tmpItemMasterPurchaseSalesType') IS NOT NULL
                    BEGIN
                        DROP TABLE #tmpItemMasterPurchaseSalesType
                    END

				CREATE TABLE #tmpItemMasterPurchaseSalesType
				(
					[ItemMasterId] [bigint]  NULL,
					[PartNumber] [varchar](50)  NULL,
					[PP_UOMId] [bigint]  NULL,
					[PP_CurrencyId] [int]  NULL,
					[PP_FXRatePerc] [decimal](18, 2)  NULL,
					[PP_VendorListPrice] [decimal](18, 2) NULL,
					[PP_LastListPriceDate] [datetime2](7) NULL,
					[PP_PurchaseDiscPerc] [int] NULL,
					[PP_PurchaseDiscAmount] [decimal](18, 2) NULL,
					[PP_LastPurchaseDiscDate] [datetime2](7) NULL,
					[PP_UnitPurchasePrice] [decimal](18, 2) NULL,
					[SP_FSP_UOMId] [bigint] NULL,
					[SP_FSP_CurrencyId] [int] NULL,
					[SP_FSP_FXRatePerc] [decimal](18, 2)  NULL,
					[SP_FSP_FlatPriceAmount] [decimal](18, 2) NULL,
					[SP_FSP_LastFlatPriceDate] [datetime2](7) NULL,
					[SP_CalSPByPP_MarkUpPercOnListPrice] [int] NULL,
					[SP_CalSPByPP_MarkUpAmount] [decimal](18, 2) NULL,
					[SP_CalSPByPP_LastMarkUpDate] [datetime2](7) NULL,
					[SP_CalSPByPP_BaseSalePrice] [decimal](18, 2) NULL,
					[SP_CalSPByPP_SaleDiscPerc] [int] NULL,
					[SP_CalSPByPP_SaleDiscAmount] [decimal](18, 2) NULL,
					[SP_CalSPByPP_LastSalesDiscDate] [datetime2](7) NULL,
					[SP_CalSPByPP_UnitSalePrice] [decimal](18, 2) NULL,
					[MasterCompanyId] [int]  NULL,
					[CreatedBy] [varchar](256)  NULL,
					[UpdatedBy] [varchar](256)  NULL,
					[CreatedDate] [datetime2](7)  NULL,
					[UpdatedDate] [datetime2](7)  NULL,
					[IsActive] [bit]  NULL,
					[IsDeleted] [bit]  NULL,
					[ItemMasterPurchaseSaleId] [bigint] ,
					[ConditionId] [bigint] NULL,
					[SalePriceSelectId] [int] NULL,
					[ConditionName] [varchar](200) NULL,
					[PP_UOMName] [varchar](200) NULL,
					[SP_FSP_UOMName] [varchar](200) NULL,
					[PP_CurrencyName] [varchar](200) NULL,
					[SP_FSP_CurrencyName] [varchar](200) NULL,
					[PP_PurchaseDiscPercValue] [decimal](18, 2) NULL,
					[SP_CalSPByPP_SaleDiscPercValue] [decimal](18, 2) NULL,
					[SP_CalSPByPP_MarkUpPercOnListPriceValue] [decimal](18, 2) NULL,
					[SalePriceSelectName] [varchar](200) NULL,
				)
				
				INSERT INTO #tmpItemMasterPurchaseSalesType
					([ItemMasterId],[PartNumber],[PP_UOMId] ,[PP_CurrencyId],[PP_FXRatePerc],[PP_VendorListPrice],
					[PP_LastListPriceDate],[PP_PurchaseDiscPerc],[PP_PurchaseDiscAmount],[PP_LastPurchaseDiscDate],
					[PP_UnitPurchasePrice],[SP_FSP_UOMId], [SP_FSP_CurrencyId],[SP_FSP_FXRatePerc],[SP_FSP_FlatPriceAmount],
					[SP_FSP_LastFlatPriceDate],[SP_CalSPByPP_MarkUpPercOnListPrice] ,[SP_CalSPByPP_MarkUpAmount],
					[SP_CalSPByPP_LastMarkUpDate],[SP_CalSPByPP_BaseSalePrice] ,[SP_CalSPByPP_SaleDiscPerc] ,
					[SP_CalSPByPP_SaleDiscAmount],[SP_CalSPByPP_LastSalesDiscDate],	[SP_CalSPByPP_UnitSalePrice] ,
					[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted],
					[ItemMasterPurchaseSaleId] ,[ConditionId],[SalePriceSelectId] ,[ConditionName],[PP_UOMName] ,
					[SP_FSP_UOMName],[PP_CurrencyName],[SP_FSP_CurrencyName] ,[PP_PurchaseDiscPercValue],[SP_CalSPByPP_SaleDiscPercValue] ,
					[SP_CalSPByPP_MarkUpPercOnListPriceValue],[SalePriceSelectName])		
					
					SELECT [ItemMasterId],[PartNumber],[PurchaseUnitOfMeasureId],[PurchaseCurrencyId],0,@UnitPurchasePrice,
					null,-1,0,null,
					@UnitPurchasePrice,[PurchaseUnitOfMeasureId],[SalesCurrencyId],0,@UnitSalePrice,
					null,-1 ,0,
					null,null ,null ,
					null,null,	@UnitSalePrice ,
					IM.[MasterCompanyId],IM.[CreatedBy],IM.[CreatedBy],GETUTCDATE() ,GETUTCDATE() ,1 ,0,
					0 ,@ConditionId,1 ,null,null ,
					null,null,null ,null,null ,
					null,'Flat'
					FROM [DBO].[ItemMaster] IM WITH(NOLOCK)
					--JOIN [DBO].[ItemMaster] IM WITH(NOLOCK) ON IMPS.ItemMasterId = IM.ItemMasterId
					LEFT JOIN [DBO].[Condition] CON WITH(NOLOCK) ON CON.ConditionId = @ConditionId
					WHERE IM.ItemMasterId = @ItemMasterId AND CON.ConditionId = @ConditionId;

		  --select * from #tmpItemMasterPurchaseSalesType
		  MERGE dbo.ItemMasterPurchaseSale AS TARGET  
		  USING #tmpItemMasterPurchaseSalesType AS SOURCE ON (SOURCE.ItemMasterId = TARGET.ItemMasterId AND SOURCE.ConditionId = TARGET.ConditionId)   
		  WHEN MATCHED 
		  THEN UPDATE   
		  SET   		
		  TARGET.[PP_VendorListPrice] = SOURCE.[PP_UnitPurchasePrice],
		  TARGET.[PP_PurchaseDiscPerc] = -1,
		  TARGET.[PP_PurchaseDiscAmount] = 0,
		  TARGET.[PP_UnitPurchasePrice] = SOURCE.[PP_UnitPurchasePrice],
		  TARGET.[SalePriceSelectId] = 1,
		  TARGET.[SP_FSP_FlatPriceAmount] = SOURCE.[SP_CalSPByPP_UnitSalePrice],
		  TARGET.[SP_CalSPByPP_MarkUpPercOnListPrice] = -1,
		  TARGET.[SP_CalSPByPP_MarkUpAmount] = 0,
		  TARGET.[SP_CalSPByPP_LastSalesDiscDate] = NULL,
		  TARGET.[SP_CalSPByPP_UnitSalePrice] = SOURCE.[SP_CalSPByPP_UnitSalePrice]

		  WHEN NOT MATCHED BY TARGET  
		  THEN  
		  INSERT([ItemMasterId],[PartNumber],[PP_UOMId] ,[PP_CurrencyId],[PP_FXRatePerc],[PP_VendorListPrice],
					[PP_LastListPriceDate],[PP_PurchaseDiscPerc],[PP_PurchaseDiscAmount],[PP_LastPurchaseDiscDate],
					[PP_UnitPurchasePrice],[SP_FSP_UOMId], [SP_FSP_CurrencyId],[SP_FSP_FXRatePerc],[SP_FSP_FlatPriceAmount],
					[SP_FSP_LastFlatPriceDate],[SP_CalSPByPP_MarkUpPercOnListPrice] ,[SP_CalSPByPP_MarkUpAmount],
					[SP_CalSPByPP_LastMarkUpDate],[SP_CalSPByPP_BaseSalePrice] ,[SP_CalSPByPP_SaleDiscPerc] ,
					[SP_CalSPByPP_SaleDiscAmount],[SP_CalSPByPP_LastSalesDiscDate],	[SP_CalSPByPP_UnitSalePrice] ,
					[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate] ,[UpdatedDate] ,[IsActive] ,[IsDeleted],
					[ConditionId],[SalePriceSelectId] ,[ConditionName],[PP_UOMName] ,
					[SP_FSP_UOMName],[PP_CurrencyName],[SP_FSP_CurrencyName] ,[PP_PurchaseDiscPercValue],[SP_CalSPByPP_SaleDiscPercValue] ,
					[SP_CalSPByPP_MarkUpPercOnListPriceValue],[SalePriceSelectName])	
					
					VALUES(SOURCE.[ItemMasterId],SOURCE.[PartNumber],SOURCE.[PP_UOMId] ,SOURCE.[PP_CurrencyId],SOURCE.[PP_FXRatePerc],SOURCE.[PP_VendorListPrice],
					SOURCE.[PP_LastListPriceDate],SOURCE.[PP_PurchaseDiscPerc],SOURCE.[PP_PurchaseDiscAmount],SOURCE.[PP_LastPurchaseDiscDate],
					SOURCE.[PP_UnitPurchasePrice],SOURCE.[SP_FSP_UOMId],SOURCE.[SP_FSP_CurrencyId],SOURCE.[SP_FSP_FXRatePerc],SOURCE.[SP_FSP_FlatPriceAmount],
					SOURCE.[SP_FSP_LastFlatPriceDate],SOURCE.[SP_CalSPByPP_MarkUpPercOnListPrice] ,SOURCE.[SP_CalSPByPP_MarkUpAmount],
					SOURCE.[SP_CalSPByPP_LastMarkUpDate],SOURCE.[SP_CalSPByPP_BaseSalePrice] ,SOURCE.[SP_CalSPByPP_SaleDiscPerc] ,
					SOURCE.[SP_CalSPByPP_SaleDiscAmount],SOURCE.[SP_CalSPByPP_LastSalesDiscDate],SOURCE.[SP_CalSPByPP_UnitSalePrice] ,
					SOURCE.[MasterCompanyId],SOURCE.[CreatedBy],SOURCE.[UpdatedBy],SOURCE.[CreatedDate] ,SOURCE.[UpdatedDate] ,SOURCE.[IsActive] ,SOURCE.[IsDeleted],
					SOURCE.[ConditionId],SOURCE.[SalePriceSelectId] ,SOURCE.[ConditionName],SOURCE.[PP_UOMName] ,
					SOURCE.[SP_FSP_UOMName],SOURCE.[PP_CurrencyName],SOURCE.[SP_FSP_CurrencyName] ,SOURCE.[PP_PurchaseDiscPercValue],SOURCE.[SP_CalSPByPP_SaleDiscPercValue] ,
					SOURCE.[SP_CalSPByPP_MarkUpPercOnListPriceValue],SOURCE.[SalePriceSelectName]);

					SET @MainPartLoopID = @MainPartLoopID - 1;
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
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateConditionById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' +  CAST(ISNULL(@ItemMasterId, '') as varchar(100))
			  + '@MasterCompanyId = ''' + CAST(ISNULL(@ConditionId, '') AS varchar(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END