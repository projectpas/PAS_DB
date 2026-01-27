/*************************************************************             
 ** File:   [USP_SearchBulkStockData]             
 ** Author:  AMIT GHEDIYA  
 ** Description: This stored procedure is used to Get Bulk Stockline Adjustment listing  
 ** Purpose:           
 ** Date:   12/10/2023        
            
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date            Author                 Change Description              
 ** --   --------       -----------				--------------------------------            
    1    12/10/2023     AMIT GHEDIYA			Created
	2    06/12/2023     AMIT GHEDIYA			Modify(Added Adjustment Type column)
	3	 09/04/2025	    Ekta Chandegra	        Convert date using dbo.ConvertUTCtoLocal
    4    26/01/2026     Ayushi Patel            Enhancement: Added ViewType-based data handling (SUMMARY / DETAILS).   
-- EXEC USP_SearchBulkStockData
************************************************************************/  
CREATE    PROCEDURE [dbo].[USP_SearchBulkStockData]
	@PageNumber int = NULL,
	@PageSize int = NULL,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@GlobalFilter varchar(50) = '',
	@StatusId int = NULL,
	@BulkStkLineAdjNumber  varchar(50) = NULL,
	@CreatedBy  varchar(50) = NULL,
	@CreatedDate datetime = NULL,
	@UpdatedBy  varchar(50) = NULL,
	@UpdatedDate  datetime = NULL,
	@IsDeleted bit = NULL,
	@MasterCompanyId bigint = NULL,
	@AdjustmentType varchar(150) = NULL,
	@EmployeeId bigint,
    @ViewType VARCHAR(20) = 'SUMMARY',
    @PartNumber        VARCHAR(50) = NULL,
    @PartDescription   VARCHAR(150) = NULL,
    @Condition         VARCHAR(50) = NULL,
    @StockLineNumber   VARCHAR(50) = NULL,
    @ControlNumber     VARCHAR(50) = NULL,
    @NewQty        VARCHAR(50) = NULL,
    @UnitCost      VARCHAR(50) = NULL,
    @LastMSLevel   VARCHAR(200) = NULL,
    @AllMSLevels   VARCHAR(500) = NULL

AS
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
   BEGIN  
   DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
			SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM 
					dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN 
					dbo.TimeZone ETZ WITH (NOLOCK) 
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN 
					dbo.LegalEntity LE WITH (NOLOCK) 
					ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN 
					dbo.TimeZone LTZ WITH (NOLOCK) 
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE 
					E.EmployeeId = @EmployeeId;

    DECLARE @RecordFrom int;  
    DECLARE  @VendorRMADetailStatus VARCHAR(100)= NULL;  
    SET @RecordFrom = (@PageNumber-1) * @PageSize;  
    IF @IsDeleted IS NULL  
    BEGIN  
     SET @IsDeleted=0  
    END  
    IF @SortColumn IS NULL  
    BEGIN  
     SET @SortColumn = UPPER('CreatedDate')  
    END   
    ELSE  
    BEGIN   
     SET @SortColumn = UPPER(@SortColumn)  
    END  

	IF @StatusId=0  
    BEGIN   
     SET @StatusId = NULL  
    END   

	IF UPPER(@ViewType) = 'SUMMARY'
      BEGIN

		;WITH Result AS(  
		SELECT stadt.[Name] AS 'AdjustmentType',
					   bsadj.BulkStkLineAdjId,
					   bsadj.BulkStkLineAdjNumber,   
					   (Cast(DBO.ConvertUTCtoLocal(bsadj.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) as CreatedDate,
					   (Cast(DBO.ConvertUTCtoLocal(bsadj.UpdatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) as UpdatedDate,
					   bsadj.CreatedBy,
                       bsadj.UpdatedBy,	
					   bsadj.IsDeleted,
					   bsadj.StatusId
			   FROM dbo.BulkStockLineAdjustment bsadj WITH (NOLOCK)	
			   INNER JOIN dbo.StockLineAdjustmentType stadt ON bsadj.StockLineAdjustmentTypeId = stadt.StockLineAdjustmentTypeId
		 	  WHERE (bsadj.IsActive = 1)			     
					AND bsadj.MasterCompanyId=@MasterCompanyId AND (@StatusId IS NULL OR bsadj.StatusId = @StatusId )
		),
		FinalResult AS (  
		SELECT AdjustmentType,BulkStkLineAdjId, BulkStkLineAdjNumber, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsDeleted, StatusId FROM Result  
		WHERE  (  
		 (@GlobalFilter <>'' AND ((BulkStkLineAdjNumber LIKE '%' +@GlobalFilter+'%' ) OR   
		   (CreatedBy LIKE '%' +@GlobalFilter+'%') OR 
		   (UpdatedBy LIKE '%' +@GlobalFilter+'%') OR 
		   (CreatedDate LIKE '%' +@GlobalFilter+'%') OR  
		   (UpdatedDate LIKE '%' +@GlobalFilter+'%') OR
		   (AdjustmentType LIKE '%' +@GlobalFilter+'%') 
		   ))  
		   OR     
		   (@GlobalFilter='' AND (ISNULL(@BulkStkLineAdjNumber,'') ='' OR BulkStkLineAdjNumber LIKE  '%'+ @BulkStkLineAdjNumber+'%') AND   
		   (ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%'+ @CreatedBy+'%') AND  
		   (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%'+ @UpdatedBy+'%') AND  
		   (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE) = CAST(@CreatedDate AS DATE)) AND  
		   (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE) = CAST(@UpdatedDate AS DATE)) AND
		   (ISNULL(@AdjustmentType,'') ='' OR AdjustmentType LIKE '%'+ @AdjustmentType +'%')
		   )  
		   )),  
      ResultCount AS (Select COUNT(BulkStkLineAdjId) AS NumberOfItems FROM FinalResult)  
      SELECT AdjustmentType,BulkStkLineAdjId, BulkStkLineAdjNumber, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsDeleted, StatusId, NumberOfItems FROM FinalResult, ResultCount  
  
      ORDER BY    
	  CASE WHEN (@SortOrder=1 AND @SortColumn='AdjustmentType')  THEN AdjustmentType END ASC,
      CASE WHEN (@SortOrder=1 AND @SortColumn='BulkStkLineAdjId')  THEN BulkStkLineAdjId END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='BulkStkLineAdjNumber')  THEN BulkStkLineAdjNumber END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,   
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='AdjustmentType')  THEN AdjustmentType END DESC, 
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='BulkStkLineAdjId')  THEN BulkStkLineAdjId END DESC,  
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='BulkStkLineAdjNumber')  THEN BulkStkLineAdjNumber END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
   END  

  ELSE
      BEGIN
	  ;WITH Result AS
            (
                SELECT
                    stadt.[Name] AS AdjustmentType,
                    bsadj.BulkStkLineAdjId,
                    bsadj.BulkStkLineAdjNumber,
                    CAST(DBO.ConvertUTCtoLocal(bsadj.CreatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME) AS CreatedDate,

                    IM.PartNumber,
                    IM.PartDescription,

                    BSAD.NewQty,
                    BSAD.UnitCost,
                    BSAD.LastMSLevel,
                    BSAD.AllMSLevels,

                    STL.[Condition],
                    STL.StockLineNumber,
                    STL.ControlNumber,
                    bsadj.StatusId
                FROM dbo.BulkStockLineAdjustment bsadj WITH (NOLOCK)
                INNER JOIN dbo.StockLineAdjustmentType stadt
                    ON bsadj.StockLineAdjustmentTypeId = stadt.StockLineAdjustmentTypeId
                INNER JOIN dbo.BulkStockLineAdjustmentDetails BSAD WITH (NOLOCK)
                    ON bsadj.BulkStkLineAdjId = BSAD.BulkStkLineAdjId
                LEFT JOIN dbo.StockLine STL WITH (NOLOCK)
                    ON BSAD.StockLineId = STL.StockLineId
                LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK)
                    ON STL.ItemMasterId = IM.ItemMasterId
                WHERE
                    bsadj.MasterCompanyId = @MasterCompanyId
                    AND ISNULL(bsadj.IsDeleted, 0) = 0
                    AND (@StatusId IS NULL OR bsadj.StatusId = @StatusId )
            ),
            FinalResult AS
            (
                SELECT
                    AdjustmentType,
                    BulkStkLineAdjId,
                    BulkStkLineAdjNumber,
                    CreatedDate,
                    PartNumber,
                    PartDescription,
                    NewQty,
                    UnitCost,
                    LastMSLevel,
                    AllMSLevels,
                    [Condition],
                    StockLineNumber,
                    ControlNumber,
                    StatusId
                FROM Result
                WHERE
                (
                    @GlobalFilter <> '' AND
                    (
                        LOWER(BulkStkLineAdjNumber) LIKE '%' + LOWER(@GlobalFilter) + '%'
                        OR LOWER(PartNumber) LIKE '%' + LOWER(@GlobalFilter) + '%'
                        OR LOWER(PartDescription) LIKE '%' + LOWER(@GlobalFilter) + '%'
                        OR LOWER(StockLineNumber) LIKE '%' + LOWER(@GlobalFilter) + '%'
                        OR LOWER(ControlNumber) LIKE '%' + LOWER(@GlobalFilter) + '%'
                        OR LOWER(AdjustmentType) LIKE '%' + LOWER(@GlobalFilter) + '%'
                        OR LOWER(LastMSLevel) LIKE '%' + LOWER(@GlobalFilter) + '%'
                        OR LOWER(AllMSLevels) LIKE '%' + LOWER(@GlobalFilter) + '%'
                        OR CAST(NewQty AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%'
                        OR CAST(UnitCost AS VARCHAR(50)) LIKE '%' + @GlobalFilter + '%'
                    )
                )
                OR
                (
                    @GlobalFilter = '' AND
                    (ISNULL(@BulkStkLineAdjNumber, '') = '' OR BulkStkLineAdjNumber LIKE '%' + @BulkStkLineAdjNumber + '%')
                    AND (ISNULL(@AdjustmentType, '') = '' OR AdjustmentType LIKE '%' + @AdjustmentType + '%')
                    AND (ISNULL(@PartNumber, '') = '' OR PartNumber LIKE '%' + @PartNumber + '%')
                    AND (ISNULL(@PartDescription, '') = '' OR PartDescription LIKE '%' + @PartDescription + '%')
                    AND (ISNULL(@Condition, '') = '' OR [Condition] LIKE '%' + @Condition + '%')
                    AND (ISNULL(@StockLineNumber, '') = '' OR StockLineNumber LIKE '%' + @StockLineNumber + '%')
                    AND (ISNULL(@ControlNumber, '') = '' OR ControlNumber LIKE '%' + @ControlNumber + '%')
                    AND (ISNULL(@LastMSLevel, '') = '' OR LastMSLevel LIKE '%' + @LastMSLevel + '%')
                    AND (ISNULL(@AllMSLevels, '') = '' OR AllMSLevels LIKE '%' + @AllMSLevels + '%')
                    AND (ISNULL(@NewQty, '') = '' OR CAST(NewQty AS VARCHAR(50)) LIKE '%' + @NewQty + '%')
                    AND (ISNULL(@UnitCost, '') = '' OR CAST(UnitCost AS VARCHAR(50)) LIKE '%' + @UnitCost + '%')
                )
            ),
            ResultCount AS
            (
                SELECT COUNT(BulkStkLineAdjId) AS NumberOfItems FROM FinalResult
            )
            SELECT
                AdjustmentType,
                BulkStkLineAdjId,
                BulkStkLineAdjNumber,
                CreatedDate,
                PartNumber,
                PartDescription,
                NewQty,
                UnitCost,
                LastMSLevel,
                AllMSLevels,
                [Condition],
                StockLineNumber,
                ControlNumber,
                StatusId,
                NumberOfItems
            FROM FinalResult, ResultCount
            ORDER BY
                CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ADJUSTMENTTYPE') THEN AdjustmentType END ASC,
                CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ADJUSTMENTTYPE') THEN AdjustmentType END DESC,

                CASE WHEN (@SortOrder = 1 AND @SortColumn = 'BULKSTKLINEADJNUMBER') THEN BulkStkLineAdjNumber END ASC,
                CASE WHEN (@SortOrder = -1 AND @SortColumn = 'BULKSTKLINEADJNUMBER') THEN BulkStkLineAdjNumber END DESC,

                CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CREATEDDATE') THEN CreatedDate END ASC,
                CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDDATE') THEN CreatedDate END DESC,

                CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PARTNUMBER') THEN PartNumber END ASC,
                CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTNUMBER') THEN PartNumber END DESC,

                CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PARTDESCRIPTION') THEN PartDescription END ASC,
                CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTDESCRIPTION') THEN PartDescription END DESC,

                CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CONDITION') THEN [Condition] END ASC,
                CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CONDITION') THEN [Condition] END DESC,

                CASE WHEN (@SortOrder = 1 AND @SortColumn = 'STOCKLINENUMBER') THEN StockLineNumber END ASC,
                CASE WHEN (@SortOrder = -1 AND @SortColumn = 'STOCKLINENUMBER') THEN StockLineNumber END DESC,

                CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CONTROLNUMBER') THEN ControlNumber END ASC,
                CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CONTROLNUMBER') THEN ControlNumber END DESC,

                CASE WHEN (@SortOrder = 1 AND @SortColumn = 'NEWQTY') THEN NewQty END ASC,
                CASE WHEN (@SortOrder = -1 AND @SortColumn = 'NEWQTY') THEN NewQty END DESC,

                CASE WHEN (@SortOrder = 1 AND @SortColumn = 'UNITCOST') THEN UnitCost END ASC,
                CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UNITCOST') THEN UnitCost END DESC,

                CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LASTMSLEVEL') THEN LastMSLevel END ASC,
                CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LASTMSLEVEL') THEN LastMSLevel END DESC,

                CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ALLMSLEVELS') THEN AllMSLevels END ASC,
                CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ALLMSLEVELS') THEN AllMSLevels END DESC


            OFFSET @RecordFrom ROWS
            FETCH NEXT @PageSize ROWS ONLY;

        END
        END
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    --ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_VendorRMA_GetVendorRMAList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END