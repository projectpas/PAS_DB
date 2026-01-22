/*************************************************************           
 ** File:   [USP_CreateAssetAccountingBatch]           
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used to USP_CreateAssetAccountingBatch
 ** Purpose:         
 ** Date:   02/12/2022      
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    02/12/2022  Subhash Saliya     Created
	2	 12/08/2023  Satish Gohil	 Modify(Formetted)

     
-- EXEC USP_CreateAssetAccountingBatch

************************************************************************/

CREATE    PROCEDURE [dbo].[USP_CreateAssetAccountingBatch]
	@MasterCompanyId int 
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
		DECLARE @AssetInventoryId int;
        DECLARE @DeprFrequency varchar(50);
        DECLARE @AssetCreateDate Datetime2(7);
        DECLARE @ExistStatus varchar(50);
        DECLARE @DATEDIFF decimal(18,2)=0;
        DECLARE @YearDIFF bigint=0;
        DECLARE @MonthDIFF bigint=0;
        DECLARE @DividedDaysDIFF decimal(18,2)=0;
        DECLARE @AssetLife int;
        DECLARE @TangibleClassId int;
        DECLARE @RC int
        DECLARE @Qty int =1
        DECLARE @Amount decimal(18,2)
        DECLARE @ModuleName varchar(200) ='AssetInventory'
        DECLARE @UpdateBy varchar(200)
        DECLARE @StockType varchar(100)='AssetPeriodDepreciation'
        DECLARE @BatchId bigint

		DECLARE @AssetStatusid Int;
		DECLARE @QtrDays Int =90;
		DECLARE @YearDays Int =365;
		DECLARE @DeprFrequencyMonthly varchar(500) ='MTHLY,MONTHLY'
		DECLARE @DeprFrequencyQUATERLY varchar(500) ='QUATERLY,QTLY'
		DECLARE @DeprFrequencyYEARLY varchar(500) ='YEARLY,YRLY'
	
		SELECT TOP 1  @AssetStatusid=AssetStatusid from AssetStatus WITH(NOLOCK) 
		WHERE UPPER(name) ='DEPRECIATING' and MasterCompanyId=@MasterCompanyId
		
		DECLARE db_cursor CURSOR FOR 
        SELECT AssetInventoryId  
        FROM AssetInventory as asm where (((asm.DepreciationFrequencyName in (SELECT Item FROM DBO.SPLITSTRING(@DeprFrequencyMonthly,',')) and (CONVERT(VARCHAR(6), GETDATE(), 112) != CONVERT(VARCHAR(6), asm.EntryDate, 112)) ) OR
							            (asm.DepreciationFrequencyName in (SELECT Item FROM DBO.SPLITSTRING(@DeprFrequencyQUATERLY,',')) and (ABS(CAST((DATEDIFF(month, CAST(asm.EntryDate as date),CAST(getdate() as date)))  AS INT)) % 3 =0))  OR
									    (asm.DepreciationFrequencyName in (SELECT Item FROM DBO.SPLITSTRING(@DeprFrequencyYEARLY,',')) and  (ABS(CAST((DATEDIFF(month, CAST(asm.EntryDate as date),CAST(getdate() as date)))  AS INT)) % 12 =0)) ) 
							                            AND ((DATEDIFF(month, CAST(asm.EntryDate as date),CAST(getdate() as date))) <= asm.AssetLife)
							                            AND (asm.IsDeleted = 0) AND (asm.InventoryStatusId=1) AND (asm.IsTangible=1) AND (asm.IsDepreciable=1) AND (asm.AssetStatusId=@AssetStatusid) 			     
							                            AND (asm.MasterCompanyId = @MasterCompanyId) AND (ISNULL(asm.IsActive,1) = 1))
		
		OPEN db_cursor  
        FETCH NEXT FROM db_cursor INTO @AssetInventoryId  
		WHILE @@FETCH_STATUS = 0  
        BEGIN
			SELECT @Amount=isnull(AI.UnitCost,0),@UpdateBy=ai.UpdatedBy,@TangibleClassId=Asset.TangibleClassId,@DeprFrequency=DepreciationFrequencyName,@AssetCreateDate=AI.EntryDate 
			FROM dbo.AssetInventory AI WITH(NOLOCK)
            INNER JOIN dbo.Asset WITH(NOLOCK) on Asset.AssetRecordId=AI.AssetRecordId
            WHERE AI.AssetInventoryId= @AssetInventoryId
          
			EXECUTE @RC = [dbo].[USP_CreateBatch_Asset_inventory]  @AssetInventoryId,@Qty,@Amount,@ModuleName,@UpdateBy,@MasterCompanyId,@StockType,@BatchId OUTPUT

			FETCH NEXT FROM db_cursor INTO @AssetInventoryId 
		END
		CLOSE db_cursor
        DEALLOCATE db_cursor
	END
	END TRY
	BEGIN CATCH      
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'CreateAssetAccountingBatch' 
        , @ProcedureParameters VARCHAR(3000)  = ''
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