/*************************************************************           
** Author:  <BHARGAV SALIYA>  
** Create date: <20/11/2024>  [mm/dd/yyyy]
** Description: <Get Saved General Ledger Params ById>  
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author					Change Description  
** --   --------		-------					--------------------------------
** 1	20/11/2024		BHARGAV SALIYA			Created
** 2	26/11/2024		BHARGAV SALIYA			Change The Filter Field Stockline Number To Control Number
**************************************************************/ 

CREATE     PROCEDURE [dbo].[USP_StockInventorySearchParams_ById]
	@stockInventorySearchParamsId BIGINT = NULL,
	@MasterCompanyId BIGINT = NULL
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT	
					StockInventorySearchParamsId,
					UrlName,
					FromReceivedDate,
					ToReceivedDate,
					ISNULL(FromControlNumber, '') AS 'FromControlNumber',
					ISNULL(ToControlNumber, '') AS 'ToControlNumber',
					ISNULL(FromUnitCost, '') AS 'FromUnitCost',
					ISNULL(ToUnitCost, '') AS 'ToUnitCost',
					ISNULL(ItemMasterId, 0) AS 'ItemMasterId',
					ISNULL(VendorId, 0) AS 'VendorId',
					ISNULL(ConditionId, 0) AS 'ConditionId',
					ISNULL(LotId, 0) AS 'LotId',
					ISNULL(TraceableTo, 0) AS 'TraceableTo',
					ISNULL(SiteId, 0) AS 'SiteId',
					ISNULL(WarehouseId, 0) AS 'WarehouseId',
					ISNULL(LocationId, 0) AS 'LocationId',
					ISNULL(ShelfId, 0) AS 'ShelfId',
					ISNULL(BinId, 0) AS 'BinId',
					ISNULL(PoRoRefrences, 0) AS 'PoRoRefrences',
					ISNULL(Level1, '') AS 'Level1',
					ISNULL(Level2, '') AS 'Level2',
					ISNULL(Level3, '') AS 'Level3',
					ISNULL(Level4, '') AS 'Level4',
					ISNULL(Level5, '') AS 'Level5',
					ISNULL(Level6, '') AS 'Level6',
					ISNULL(Level7, '') AS 'Level7',
					ISNULL(Level8, '') AS 'Level8',
					ISNULL(Level9, '') AS 'Level9',
					ISNULL(Level10, '') AS 'Level10',
					MasterCompanyId,
					CreatedBy,
					CreatedDate,
					UpdatedBy,
					UpdatedDate,
					IsActive,
					IsDeleted
				FROM dbo.StockInventorySearchParams SISP WITH (NOLOCK)
				WHERE	SISP.StockInventorySearchParamsId = @stockInventorySearchParamsId AND SISP.MasterCompanyId = @MasterCompanyId

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_StockInventorySearchParams_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@integrationID = '''+ ISNULL(@stockInventorySearchParamsId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
			            
END