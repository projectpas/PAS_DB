/*************************************************************           
 ** File:   [USP_VendorRMA_GetVendorRMAList]          
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to Create for get Vendor RMA List data.
 ** Purpose:         
 ** Date:   06/13/2023        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------          
    1    06/13/2023   Amit Ghediya			Created
	2    06/16/2023   Amit Ghediya			Updated Header RMA number to Detail RMANumber
	3    06/22/2023   Devendra Shekh		added vendorcreditmemo join to get vendorcreditmemoid
	4    06/16/2023   Amit Ghediya			Updated Condition for RMA View
	5    06/27/2023   Amit Ghediya			Updated for html Tag replace due to STUFF fun.
	6    06/28/2023   Devendra Shekh		added new filter and join for rmadetail status for vendorcreditmemolist
	7    07/04/2023   Devendra Shekh		added new where condition to filter list by vendorrmaid
	8    07/05/2023   Amit Ghediya		    added ShippedDate & shiprefrence.
	9    07/05/2023   Moin Bloch		    added VendorRMAStatusId.
	10   07/07/2023   Amit Ghediya		    Removed Duplicated populated items.
	11   07/07/2023   Moin Bloch            Addred Receiving Qty Field
	12   29-03-2024   Shrey Chandegara            Add RevisedStocklineId
	13   22/07/2024   Amit Ghediya		    Optimization sp.
	14   22-07-2024   Shrey Chandegara      Modify For date filter issue(use this function @CurrntEmpTimeZoneDesc )
	15   06-04-2026	  Amit Ghediya			UOM Conversion Changes [PN-15140]  
	16   03-06-2026	  Priyansh Patel		UOM Conversion Changes for extended cost [PN-16610]  
	17   19-06-2026	  Priyansh Patel		Add Condition to skip fn_ConvertUOM call [PN-16911]
	18    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	19    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	20    23/July/2026			 RAJESH GAMI						[PN-17350] - Removed leftover IsNonStock=0 exclusion filters.
	21   10-Sep-2026   Bhargav Saliya    [PN-17849] Part Number filter: normalize dashes(-)/slashes("\","/")/underscore(_)
	22   02-Oct-2026   Bhargav Saliya    Performance: materialize the filtered result once into a temp table (the CTE was
	                                     evaluated twice - once for COUNT, once for the page - re-running every fn_ConvertUOM
	                                     call), compute QuantityReceived only for the rows of the requested page, add a
	                                     deterministic tie-breaker to the paging sort, fix Summary-view sort on Condition,
	                                     fix missing comma that returned VendorRMADetailStatus under the name VendorRMANumber.
 EXECUTE USP_VendorRMA_GetVendorRMAList 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_VendorRMA_GetVendorRMAList]  
@PageNumber INT,  
@PageSize INT,  
@SortColumn VARCHAR(50)=null,  
@SortOrder INT,  
@GlobalFilter VARCHAR(50) = null,  
@RMANumber VARCHAR(100) = NULL,
@OpenDate DATETIME=null, 
@VendorRMAStatus VARCHAR(100)= NULL,
@VendorRMAReturnReason VARCHAR(100)= NULL,
@ShippedDate DATETIME=null,
@ShipRefrence VARCHAR(100) NULL,
@ReferenceNumber VARCHAR(100) NULL,
@Partnumber VARCHAR(100) NULL,
@SerialNumber VARCHAR(100) NULL,
@StockLineNumber VARCHAR(100) NULL,
@PartDescription VARCHAR(100) NULL,
@Qty INT=NULL,
@UnitCost varchar(50)=NULL, --DECIMAL(18,2)=NULL,  
@ExtendedCost varchar(50)=NULL, --DECIMAL(18,2)=NULL, 
@ReplacementDate DATETIME=null,
@ReceiverID BIGINT=NULL,
@RefundedDate DATETIME=null,
@RefundedRef VARCHAR(100) NULL,
@Memo VARCHAR(MAX) NULL,
@CreatedDate DATETIME=NULL,  
@UpdatedDate  datetime=NULL,  
@IsDeleted BIT=NULL,  
@CreatedBy VARCHAR(50)=NULL,  
@UpdatedBy VARCHAR(50)=NULL,  
@MasterCompanyId INT=NULL,
@ViewType VARCHAR(50)=NULL,
@StatusType INT=NULL,
@VendorRMADetailStatusId  INT=NULL,
@VendorRMAId BIGINT=NULL,
@VendorName VARCHAR(100) NULL,
@QtyShipped varchar(50)=NULL,
@Condition VARCHAR(50)=NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  --BEGIN TRANSACTION  
   BEGIN  
    DECLARE @RecordFrom int;
    DECLARE @Count INT = 0;
    DECLARE  @VendorRMADetailStatus VARCHAR(100)= NULL;
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId 
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

	IF @StatusType=0  
    BEGIN   
     SET @StatusType = NULL  
    END   

	IF @VendorRMADetailStatusId IS NOT NULL
	BEGIN 
		SET @VendorRMADetailStatus = (SELECT [VendorRMAStatus] FROM [dbo].[VendorRMAStatus] WITH (NOLOCK) WHERE [VendorRMAStatusId] = @VendorRMADetailStatusId)
	END
  
	IF @ViewType = 'detailview'
	BEGIN	
		;WITH Result AS(  
		SELECT 
			RMA.[VendorRMAId] AS 'VendorRMAId',
			V.[VendorId] AS 'VendorId',
			ISNULL(V.[VendorName],'') AS 'VendorName',
			ISNULL(V.[VendorCode],'') AS 'VendorCode',
			RMA.[RMANumber] AS 'RMANumber',
			RMA.[OpenDate] AS 'OpenDate',
			RMA.[VendorRMAStatusId] AS 'VendorRMAStatusId',
			RMAS.[StatusName] AS 'RMAStatusType',
			RMAD.[VendorRMAReturnReasonId] AS 'VendorRMAReturnReasonId',
			RMAR.[Reason] AS 'ReasonType',
			RMS.CreatedDate AS 'ShippedDate',
			SI.RMAShippingNum AS 'ShipRefrence',
			(CASE WHEN SL.[PurchaseOrderId] > 0 THEN PO.[PurchaseOrderNumber] WHEN SL.[RepairOrderId] > 0 THEN RO.[RepairOrderNumber] ELSE '' END) 'ReferenceNumberType',
			(CASE WHEN SL.[PurchaseOrderId] > 0 THEN 1 ELSE 0 END) 'IsPORO',
			IM.[ItemMasterId] AS 'ItemMasterId',
			IM.[partnumber] AS 'PartNumberType',	
			RMAD.[SerialNumber] AS 'SerialNumberType',
			SL.[StockLineId] AS 'StockLineIdType',
			SL.[StockLineNumber] AS 'StockLineNumberType',
			IM.[PartDescription] AS 'PartDescriptionType',
			(CASE WHEN NULLIF(IM.[StockUnitOfMeasure], '') IS NULL OR NULLIF(IM.[PurchaseUnitOfMeasure], '') IS NULL OR IM.[StockUnitOfMeasure] = IM.[PurchaseUnitOfMeasure] THEN ISNULL(RMAD.[Qty], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(RMAD.[Qty], 0),IM.[StockUnitOfMeasure],IM.[PurchaseUnitOfMeasure],0,IM.[MasterCompanyId]) END) AS 'QtyType',
			(CASE WHEN NULLIF(IM.[StockUnitOfMeasure], '') IS NULL OR NULLIF(IM.[PurchaseUnitOfMeasure], '') IS NULL OR IM.[StockUnitOfMeasure] = IM.[PurchaseUnitOfMeasure] THEN ISNULL(RMAD.[UnitCost], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(RMAD.[UnitCost], 0),IM.[StockUnitOfMeasure],IM.[PurchaseUnitOfMeasure],1,IM.[MasterCompanyId]) END) AS 'UnitCostType',
			(CASE WHEN NULLIF(IM.[StockUnitOfMeasure], '') IS NULL OR NULLIF(IM.[PurchaseUnitOfMeasure], '') IS NULL OR IM.[StockUnitOfMeasure] = IM.[PurchaseUnitOfMeasure] THEN ISNULL(RMAD.[ExtendedCost], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(RMAD.[ExtendedCost], 0),IM.[StockUnitOfMeasure],IM.[PurchaseUnitOfMeasure],1,IM.[MasterCompanyId]) END) AS 'ExtendedCostType',
			RMAD.[ReferenceId] AS 'ReferenceIdType',
			RMAD.RevisedStocklineId,
			'' AS 'ReplacementDate',
			'' AS 'ReceiverID',
			'' AS 'RefundedDate',
			'' AS 'RefundedRef',
			RMAD.[Notes] AS 'MemoType',
			RMA.[CreatedDate], 
			RMA.[UpdatedDate], 
			RMA.[UpdatedBy], 
			RMA.[CreatedBy],
			VCM.VendorCreditMemoId as 'VendorCreditMemoId',
			VS.VendorRMAStatus as 'VendorRMADetailStatus',
			RMA.RMANumber as 'VendorRMANumber',
			RMAD.ModuleId,
		(CASE WHEN NULLIF(IM.[StockUnitOfMeasure], '') IS NULL OR NULLIF(IM.[PurchaseUnitOfMeasure], '') IS NULL OR IM.[StockUnitOfMeasure] = IM.[PurchaseUnitOfMeasure] THEN ISNULL(RMS.QtyShipped, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(RMS.QtyShipped, 0),IM.[StockUnitOfMeasure],IM.[PurchaseUnitOfMeasure],0,IM.[MasterCompanyId]) END) AS 'QtyShipped',
			RMAD.VendorRMADetailId,
			-- QuantityReceived is neither filtered nor sorted on, so it is computed below for the current page only.
			SL.Condition
		FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
		INNER JOIN [DBO].[Vendor] V WITH (NOLOCK) ON RMA.VendorId = V.VendorId
		LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.[VendorRMAId] = RMAD.[VendorRMAId]
		LEFT JOIN [DBO].[VendorRMAHeaderStatus] RMAS WITH (NOLOCK) ON RMA.[VendorRMAStatusId] = RMAS.[VendorRMAStatusId]
		LEFT JOIN [DBO].[VendorRMAReturnReason] RMAR WITH (NOLOCK) ON RMAD.[VendorRMAReturnReasonId] = RMAR.[VendorRMAReturnReasonId]
		LEFT JOIN [DBO].[Stockline] SL WITH (NOLOCK) ON RMAD.[StockLineId] = SL.[StockLineId]
		LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON RMAD.[ItemMasterId] = IM.[ItemMasterId]
		LEFT JOIN [DBO].[PurchaseOrder] PO WITH (NOLOCK) ON SL.[PurchaseOrderId] = PO.[PurchaseOrderId] 
		LEFT JOIN [DBO].[RepairOrder] RO WITH (NOLOCK) ON SL.[RepairOrderId] = RO.[RepairOrderId]
		LEFT JOIN [DBO].[VendorCreditMemo] VCM WITH (NOLOCK) ON VCM.VendorRMAId = RMA.VendorRMAId
		LEFT JOIN [DBO].[VendorRMAStatus] VS WITH (NOLOCK) ON RMAD.VendorRMAStatusId = VS.VendorRMAStatusId
		LEFT JOIN [DBO].[RMAShippingItem] RMS WITH (NOLOCK) ON RMAD.VendorRMADetailId = RMS.VendorRMADetailId
		LEFT JOIN [DBO].[RMAShipping] SI WITH (NOLOCK) ON RMS.RMAShippingId = SI.RMAShippingId
		--OUTER APPLY(
		--	SELECT ISNULL(SUM(ISNULL(SL.[Quantity],0)),0) AS QuantityReceived 
		--	FROM [dbo].[Stockline] SL WITH(NOLOCK) 
		--	WHERE SL.[VendorRMAId] = RMA.[VendorRMAId] 
		--	  AND SL.[VendorRMADetailId] = RMAD.[VendorRMADetailId] 
		--	  AND SL.[IsParent] = 1 
		--	  AND SL.[IsDeleted] = 0		
		--) AS RQTY

		WHERE RMA.[MasterCompanyId] = @MasterCompanyId AND (@StatusType IS NULL OR RMA.VendorRMAStatusId = @StatusType )  --RMA.VendorRMAStatusId = CASE WHEN @StatusType = 0 THEN RMA.VendorRMAStatusId  ELSE @StatusType END --AND RMA.[VendorRMAId] = CASE WHEN @VendorRMAId != 0 and @VendorRMAId is not null THEN @VendorRMAId ELSE RMAD.[VendorRMAId] END
		),
    FinalResult AS (  
    SELECT VendorRMAId, VendorId, VendorName, VendorCode, RMANumber, OpenDate, VendorRMAStatusId, RMAStatusType, VendorRMAReturnReasonId, ReasonType, ShippedDate, ShipRefrence,   
      ReferenceNumberType, IsPORO, ItemMasterId, PartNumberType, StockLineIdType, SerialNumberType, StockLineNumberType, PartDescriptionType, QtyType, UnitCostType, ExtendedCostType,  ReferenceIdType,RevisedStocklineId, 
      ReplacementDate, ReceiverID, RefundedDate, RefundedRef, MemoType, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, VendorCreditMemoId, VendorRMADetailStatus, 
	  VendorRMANumber, ModuleId, QtyShipped, VendorRMADetailId,Condition FROM Result
    WHERE  (
     (@GlobalFilter <>'' AND ((RMANumber LIKE '%' +@GlobalFilter+'%' ) OR   
       (OpenDate LIKE '%' +@GlobalFilter+'%') OR  
       (RMAStatusType LIKE '%' +@GlobalFilter+'%') OR  
       (ReasonType LIKE '%' +@GlobalFilter+'%') OR  
       (ShippedDate LIKE '%' +@GlobalFilter+'%') OR  
       (ShipRefrence LIKE '%'+@GlobalFilter+'%') OR  
       (ReferenceNumberType LIKE '%' +@GlobalFilter+'%') OR  
       (PartNumberType LIKE '%' +@GlobalFilter+'%' OR dbo.fn_NormalizePartNumber(PartNumberType) LIKE '%' + dbo.fn_NormalizePartNumber(@GlobalFilter) + '%') OR  
       (SerialNumberType LIKE '%' +@GlobalFilter+'%') OR  
       (StockLineNumberType LIKE '%' +@GlobalFilter+'%') OR  
       (PartDescriptionType LIKE '%' +@GlobalFilter+'%') OR  
       (QtyType LIKE '%' +@GlobalFilter+'%') OR  
       (UnitCostType LIKE '%' +@GlobalFilter+'%') OR  
       (ExtendedCostType LIKE '%' +@GlobalFilter+'%') OR 
	   (ReplacementDate LIKE '%' +@GlobalFilter+'%') OR
       (ReceiverID LIKE '%' +@GlobalFilter+'%') OR  
	   (RefundedDate LIKE '%' +@GlobalFilter+'%') OR  
	   (RefundedRef LIKE '%' +@GlobalFilter+'%') OR  
	   (VendorName LIKE '%' +@GlobalFilter+'%') OR  
	   (MemoType LIKE '%' +@GlobalFilter+'%') OR  
       (CreatedDate LIKE '%' +@GlobalFilter+'%') OR  
       (UpdatedDate LIKE '%' +@GlobalFilter+'%') OR
	   (Condition LIKE '%' +@GLOBALFILTER+'%')
       ))  
       OR     
       (@GlobalFilter='' AND (ISNULL(@RMANumber,'') ='' OR RMANumber LIKE  '%'+ @RMANumber+'%') AND   
       (ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS DATE) = CAST(@OpenDate AS DATE)) AND  
       (ISNULL(@VendorRMAStatus,'') ='' OR RMAStatusType LIKE  '%'+@VendorRMAStatus+'%') AND  
       (ISNULL(@VendorRMAReturnReason,'') ='' OR ReasonType LIKE '%'+@VendorRMAReturnReason+'%') AND  
       (ISNULL(@ShippedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(ShippedDate , @CurrntEmpTimeZoneDesc )AS date) = CAST(@ShippedDate AS DATE)) AND
	   (ISNULL(@ShipRefrence,'') ='' OR ShipRefrence LIKE '%'+@ShipRefrence+'%') AND
       (ISNULL(@ReferenceNumber,'') ='' OR ReferenceNumberType LIKE '%'+@ReferenceNumber+'%') AND  
       (ISNULL(@Partnumber,'') ='' OR PartNumberType LIKE '%'+ @Partnumber+'%' OR dbo.fn_NormalizePartNumber(PartNumberType) LIKE '%' + dbo.fn_NormalizePartNumber(@Partnumber) + '%') AND  
       (ISNULL(@SerialNumber,'') ='' OR SerialNumberType LIKE '%'+ @SerialNumber+'%') AND  
       (ISNULL(@StockLineNumber,'') ='' OR StockLineNumberType LIKE '%'+ @StockLineNumber +'%') AND  
       (ISNULL(@PartDescription,'') ='' OR PartDescriptionType LIKE '%'+ @PartDescription +'%') AND  
       (ISNULL(@Qty,'') ='' OR QtyType = @Qty ) AND  
	   (ISNULL(@UnitCost,'') ='' OR CAST(UnitCostType AS VARCHAR(50)) LIKE '%' + CAST(@UnitCost AS VARCHAR(50))+ '%') AND
	   (ISNULL(@ExtendedCost,'') ='' OR CAST(ExtendedCostType AS VARCHAR(50)) LIKE '%' + CAST(@ExtendedCost AS VARCHAR(50))+ '%') AND
       (ISNULL(@ReplacementDate,'') ='' OR CAST(ReplacementDate AS DATE) = CAST(@ReplacementDate AS DATE)) and  
	   (ISNULL(@RefundedRef,'') ='' OR RefundedRef LIKE '%'+@RefundedRef+'%') AND  
	   (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+@VendorName+'%') AND  
	   (ISNULL(@QtyShipped,'') ='' OR CAST(QtyShipped AS varchar(10)) LIKE '%' + CAST(@QtyShipped AS VARCHAR(10))+ '%') AND
	   (ISNULL(@Memo,'') ='' OR MemoType LIKE '%'+@Memo+'%') AND  
       (ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%'+ @CreatedBy+'%') AND  
       (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%'+ @UpdatedBy+'%') AND  
	   (ISNULL(@VendorRMADetailStatus,'') ='' OR VendorRMADetailStatus LIKE  '%'+@VendorRMADetailStatus+'%') AND  
       (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE) = CAST(@CreatedDate AS DATE)) AND  
       (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE) = CAST(@UpdatedDate AS DATE)) AND
	    (ISNULL(@Condition,'') ='' OR Condition LIKE '%'+@Condition+'%')   
	   )  
       ))
      -- Materialize once: the filters and fn_ConvertUOM calls run a single time instead of once for COUNT and again for the page.
      SELECT * INTO #DetailResult FROM FinalResult;

      SELECT @Count = COUNT(VendorRMAId) FROM #DetailResult;

      ;WITH Paged AS (
      SELECT D.*, ROW_NUMBER() OVER (ORDER BY
      CASE WHEN (@SortOrder=1 AND @SortColumn='VENDORRMAID')  THEN VendorRMAId END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='RMANUMBER')  THEN RMANumber END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='OPENDATE')  THEN OpenDate END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='VENDORRMASTATUSID')  THEN VendorRMAStatusId END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='RMASTATUSTYPE')  THEN RMAStatusType END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='VENDORRMARETURNREASONID')  THEN VendorRMAReturnReasonId END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='REASONTYPE')  THEN ReasonType END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='SHIPPEDDATE')  THEN ShippedDate END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='SHIPREFRENCE')  THEN ShipRefrence END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='REFERENCENUMBERTYPE')  THEN ReferenceNumberType END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='ITEMMASTERID')  THEN ItemMasterId END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='SERIALNUMBERTYPE')  THEN SerialNumberType END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='STOCKLINENUMBERTYPE')  THEN StockLineNumberType END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END ASC, 
	  CASE WHEN (@SortOrder=1 AND @SortColumn='QTYTYPE')  THEN QtyType END ASC, 
	  CASE WHEN (@SortOrder=1 AND @SortColumn='UNITCOSTTYPE')  THEN UnitCostType END ASC, 
	  CASE WHEN (@SortOrder=1 AND @SortColumn='EXTENDEDCOSTTYPE')  THEN ExtendedCostType END ASC, 
	  CASE WHEN (@SortOrder=1 AND @SortColumn='REPLACEMENTDATE')  THEN ReplacementDate END ASC, 
	  CASE WHEN (@SortOrder=1 AND @SortColumn='RECEIVERID')  THEN ReceiverID END ASC, 
	  CASE WHEN (@SortOrder=1 AND @SortColumn='REFUNDEDDATE')  THEN RefundedDate END ASC, 
	  CASE WHEN (@SortOrder=1 AND @SortColumn='REFUNDEDREF')  THEN RefundedRef END ASC, 
	  CASE WHEN (@SortOrder=1 AND @SortColumn='MEMOTYPE')  THEN MemoType END ASC, 
      CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
      CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,   	 
	  CASE WHEN (@SortOrder=1 AND @SortColumn='Condition')  THEN Condition END ASC, 

      CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORRMAID')  THEN VendorRMAId END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='RMANUMBER')  THEN RMANumber END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='OPENDATE')  THEN OpenDate END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORRMASTATUSID')  THEN VendorRMAStatusId END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='RMASTATUSTYPE')  THEN RMAStatusType END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORRMARETURNREASONID')  THEN VendorRMAReturnReasonId END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='REASONTYPE')  THEN ReasonType END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='SHIPPEDDATE')  THEN ShippedDate END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='SHIPREFRENCE')  THEN ShipRefrence END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='REFERENCENUMBERTYPE')  THEN ReferenceNumberType END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='ITEMMASTERID')  THEN ItemMasterId END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='SERIALNUMBERTYPE')  THEN SerialNumberType END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='STOCKLINENUMBERTYPE')  THEN StockLineNumberType END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END DESC, 
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='QTYTYPE')  THEN QtyType END DESC, 
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='UNITCOSTTYPE')  THEN UnitCostType END DESC, 
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='EXTENDEDCOSTTYPE')  THEN ExtendedCostType END DESC, 
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='REPLACEMENTDATE')  THEN ReplacementDate END DESC, 
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='RECEIVERID')  THEN ReceiverID END DESC, 
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='REFUNDEDDATE')  THEN RefundedDate END DESC, 
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='REFUNDEDREF')  THEN RefundedRef END DESC, 
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='MEMOTYPE')  THEN MemoType END DESC, 
      CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
      CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
	  VendorRMAId DESC, VendorRMADetailId ASC) AS RowNo -- tie-breaker keeps paging stable (no row repeated/skipped across pages)
      FROM #DetailResult D)
      SELECT * INTO #DetailPage FROM Paged WHERE RowNo > @RecordFrom AND RowNo <= @RecordFrom + @PageSize;

      SELECT P.VendorRMAId, P.VendorId, P.VendorName, P.VendorCode, P.RMANumber, P.OpenDate, P.VendorRMAStatusId, P.RMAStatusType, P.VendorRMAReturnReasonId, P.ReasonType, P.ShippedDate, P.ShipRefrence,
      P.ReferenceNumberType, P.IsPORO, P.ItemMasterId, P.PartNumberType, P.StockLineIdType, P.SerialNumberType, P.StockLineNumberType, P.PartDescriptionType, P.QtyType, P.UnitCostType, P.ExtendedCostType,  P.ReferenceIdType, P.RevisedStocklineId,
      P.ReplacementDate, P.ReceiverID, P.RefundedDate, P.RefundedRef, P.MemoType, P.CreatedDate, P.UpdatedDate, P.CreatedBy, P.UpdatedBy, P.VendorCreditMemoId, P.VendorRMADetailStatus,
	  P.VendorRMANumber, P.ModuleId, P.QtyShipped, P.VendorRMADetailId, QR.QuantityReceived, P.Condition, @Count AS NumberOfItems
      FROM #DetailPage P
      OUTER APPLY (
			SELECT ISNULL(SUM(ISNULL((CASE WHEN NULLIF(IM.[StockUnitOfMeasure], '') IS NULL OR NULLIF(IM.[PurchaseUnitOfMeasure], '') IS NULL OR IM.[StockUnitOfMeasure] = IM.[PurchaseUnitOfMeasure] THEN ISNULL(SL.[Quantity], 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SL.[Quantity], 0),IM.[StockUnitOfMeasure],IM.[PurchaseUnitOfMeasure],0,IM.[MasterCompanyId]) END),0)),0) AS QuantityReceived
			FROM [dbo].[Stockline] SL WITH(NOLOCK)
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON SL.[ItemMasterId] = IM.[ItemMasterId]
			WHERE SL.[VendorRMAId] = P.[VendorRMAId]
			  AND SL.[VendorRMADetailId] = P.[VendorRMADetailId]
			  AND SL.[IsParent] = 1
			  AND SL.[IsDeleted] = 0
      ) QR
      ORDER BY P.RowNo;
	END
	ELSE
	BEGIN
		;With Result AS(  
			SELECT DISTINCT
				RMA.[VendorRMAId] AS 'VendorRMAId',
				V.[VendorId] AS 'VendorId',				
				ISNULL(V.[VendorName],'') AS 'VendorName',
				ISNULL(V.[VendorCode],'') AS 'VendorCode',
				RMA.[RMANumber] AS 'RMANumber',
				RMA.[OpenDate] AS 'OpenDate',
				RMA.[VendorRMAStatusId] AS 'VendorRMAStatusId',				
				'' AS 'ShippedDate',
				'' AS 'ShipRefrence',				
				'' AS 'ReplacementDate',
				'' AS 'ReceiverID',
				'' AS 'RefundedDate',
				'' AS 'RefundedRef',				
				RMA.[CreatedDate], 
				RMA.[UpdatedDate], 
				RMA.[UpdatedBy], 
				RMA.[CreatedBy],
				VCM.VendorCreditMemoId AS 'VendorCreditMemoId',				
				RMA.RMANumber AS 'VendorRMANumber',				
				0 AS ModuleId,				
				0 AS QtyShipped,
				0 AS VendorRMADetailId,
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse CAST(CONVERT(VARCHAR, MAX(SL.Quantity), 101) AS VARCHAR(MAX))  END) AS 'QuantityReceivedType',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse MAX(P.partnumber) END) AS 'PartNumberType',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse MAX(P.PartDescription) END) AS 'PartDescriptionType',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse MAX(RMAD.SerialNumber) END)  AS 'SerialNumberType',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse MAX(CASE WHEN SL.[PurchaseOrderId] > 0 THEN PO.[PurchaseOrderNumber] WHEN SL.[RepairOrderId] > 0 THEN RO.[RepairOrderNumber] ELSE '' END) END) AS 'ReferenceNumberType',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse CAST(CONVERT(VARCHAR, MAX(SL.StockLineId), 101) AS VARCHAR(MAX)) END)AS 'StockLineIdType',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse MAX(SL.StockLineNumber) END) AS 'StockLineNumberType',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse MAX(SL.Condition) END) AS 'Condition',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse MAX(VS.VendorRMAStatus) END) AS 'RMAStatusType',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse MAX(RMAR.Reason) END) AS 'ReasonType',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse CAST(CONVERT(VARCHAR, MAX(RMAD.Qty), 101) AS VARCHAR(MAX)) END) AS 'QtyType',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse CAST(CONVERT(VARCHAR, MAX(RMAD.UnitCost), 101) AS VARCHAR(MAX)) END) AS 'UnitCostType',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse CAST(CONVERT(VARCHAR, MAX(RMAD.ExtendedCost), 101) AS VARCHAR(MAX)) END) AS 'ExtendedCostType',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse CAST(CONVERT(VARCHAR, MAX(RMAD.ReferenceId), 101) AS VARCHAR(MAX)) END) AS  'ReferenceIdType',
				(CASE WHEN COUNT(RMAD.VendorRMADetailId) > 1 Then 'Multiple' ELse MAX(RMAD.Notes) END) AS 'MemoType',
				(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 Then 'Multiple' ELse MAX(VSS.VendorRMAStatus) END) AS 'VendorRMADetailStatusType'
			FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
			INNER JOIN [DBO].[Vendor] V WITH (NOLOCK) ON RMA.VendorId = V.VendorId
			LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.[VendorRMAId] = RMAD.[VendorRMAId]
			LEFT JOIN [DBO].[VendorCreditMemo] VCM WITH (NOLOCK) ON VCM.VendorRMAId = RMA.VendorRMAId
			LEFT JOIN [DBO].[Stockline] SL WITH (NOLOCK) ON RMAD.VendorRMADetailId = SL.VendorRMADetailId
			LEFT JOIN [DBO].[ItemMaster] P WITH (NOLOCK) ON RMAD.ItemMasterId = P.ItemMasterId
			LEFT JOIN [DBO].[PurchaseOrder] PO WITH (NOLOCK) ON SL.[PurchaseOrderId] = PO.[PurchaseOrderId]
			LEFT JOIN [DBO].[RepairOrder] RO WITH (NOLOCK) ON SL.[RepairOrderId] = RO.[RepairOrderId]
			LEFT JOIN [DBO].[VendorRMAStatus] VS WITH (NOLOCK) ON RMA.VendorRMAStatusId = VS.VendorRMAStatusId
			LEFT JOIN [DBO].[VendorRMAStatus] VSS WITH (NOLOCK) ON RMAD.VendorRMAStatusId = VSS.VendorRMAStatusId
			LEFT JOIN [DBO].[VendorRMAReturnReason] RMAR WITH (NOLOCK) ON RMAD.[VendorRMAReturnReasonId] = RMAR.[VendorRMAReturnReasonId]
			WHERE RMA.[MasterCompanyId] = @MasterCompanyId AND (@StatusType IS NULL OR RMA.VendorRMAStatusId = @StatusType) --AND RMAD.VendorRMAId IS NOT NULL AND RMA.[VendorRMAId] = CASE WHEN @VendorRMAId != 0 and @VendorRMAId is not null THEN @VendorRMAId ELSE RMAD.[VendorRMAId] END
			GROUP BY RMA.[VendorRMAId],
					 V.[VendorId],
					 V.[VendorName],
					 V.[VendorCode],
					 RMA.[RMANumber],
					 RMA.[OpenDate],
					 RMA.[VendorRMAStatusId],
					 RMA.[CreatedDate], 
					 RMA.[UpdatedDate], 
					 RMA.[UpdatedBy], 
					 RMA.[CreatedBy],
					 VCM.[VendorCreditMemoId],
					 SL.[VendorRMADetailId]
			)
			,
		FinalResult AS (  
		SELECT M.VendorRMAId, VendorId, VendorName, VendorCode, RMANumber, OpenDate, VendorRMAStatusId,RMAStatusType, ReasonType ,ShippedDate, ShipRefrence,   
		  ReferenceNumberType, PartNumberType,StockLineIdType, SerialNumberType, StockLineNumberType,PartDescriptionType, QtyType, UnitCostType, ExtendedCostType,  ReferenceIdType, 
		  ReplacementDate, ReceiverID, RefundedDate, RefundedRef,MemoType, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, 
		  VendorCreditMemoId, VendorRMADetailStatusType, VendorRMANumber, ModuleId, QtyShipped, VendorRMADetailId,QuantityReceivedType,Condition FROM Result M
		WHERE (  
		 (@GlobalFilter <>'' AND ((RMANumber LIKE '%' +@GlobalFilter+'%' ) OR   
		   (OpenDate LIKE '%' +@GlobalFilter+'%') OR  
		   (M.RMAStatusType LIKE '%' +@GlobalFilter+'%') OR  
		   (M.ReasonType LIKE '%' +@GlobalFilter+'%') OR  
		   (ShippedDate LIKE '%' +@GlobalFilter+'%') OR  
		   (ShipRefrence LIKE '%'+@GlobalFilter+'%') OR  
		   (M.ReferenceNumberType LIKE '%' +@GlobalFilter+'%') OR  
		   (M.PartNumberType LIKE '%' +@GlobalFilter+'%' OR dbo.fn_NormalizePartNumber(M.PartNumberType) LIKE '%' + dbo.fn_NormalizePartNumber(@GlobalFilter) + '%') OR  
		   (M.SerialNumberType LIKE '%' +@GlobalFilter+'%') OR  
		   (M.StockLineNumberType LIKE '%' +@GlobalFilter+'%') OR  
		   (M.PartDescriptionType LIKE '%' +@GlobalFilter+'%') OR  
		   (M.QtyType LIKE '%' +@GlobalFilter+'%') OR  
		   (CAST(M.UnitCostType AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR  
		   (CAST(M.ExtendedCostType AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR 
		   (ReplacementDate LIKE '%' +@GlobalFilter+'%') OR
		   (ReceiverID LIKE '%' +@GlobalFilter+'%') OR  
		   (RefundedDate LIKE '%' +@GlobalFilter+'%') OR  
		   (RefundedRef LIKE '%' +@GlobalFilter+'%') OR  
		   (VendorName LIKE '%' +@GlobalFilter+'%') OR  
		   (M.MemoType LIKE '%' +@GlobalFilter+'%') OR  
		   (CreatedDate LIKE '%' +@GlobalFilter+'%') OR  
		   (UpdatedDate LIKE '%' +@GlobalFilter+'%') OR
		   (Condition LIKE '%' +@GlobalFilter+'%') 
		   ))  
		   OR     
		   (@GlobalFilter='' AND (ISNULL(@RMANumber,'') ='' OR RMANumber LIKE  '%'+ @RMANumber+'%') AND   
		   (ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS DATE) = CAST(@OpenDate AS DATE)) AND  
		   (ISNULL(@VendorRMAStatus,'') ='' OR RMAStatusType LIKE  '%'+@VendorRMAStatus+'%') AND  
		   (ISNULL(@VendorRMAReturnReason,'') ='' OR ReasonType LIKE '%'+@VendorRMAReturnReason+'%') AND  
		   (ISNULL(@ShippedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(ShippedDate , @CurrntEmpTimeZoneDesc )AS date) = CAST(@ShippedDate AS DATE)) AND
		   (ISNULL(@ReferenceNumber,'') ='' OR ReferenceNumberType LIKE '%'+@ReferenceNumber+'%') AND  
		   (ISNULL(@Partnumber,'') ='' OR PartNumberType LIKE '%'+ @Partnumber+'%' OR dbo.fn_NormalizePartNumber(PartNumberType) LIKE '%' + dbo.fn_NormalizePartNumber(@Partnumber) + '%') AND  
		   (ISNULL(@SerialNumber,'') ='' OR SerialNumberType LIKE '%'+ @SerialNumber+'%') AND  
		   (ISNULL(@StockLineNumber,'') ='' OR StockLineNumberType LIKE '%'+ @StockLineNumber +'%') AND  
		   (ISNULL(@PartDescription,'') ='' OR PartDescriptionType LIKE '%'+ @PartDescription +'%') AND  
		   (ISNULL(@Qty,'') ='' OR QtyType = @Qty ) AND  
		   (ISNULL(@UnitCost,'') ='' OR CAST(UnitCostType AS VARCHAR(10)) LIKE '%' + CAST(@UnitCost AS VARCHAR(10))+ '%') AND
		   (ISNULL(@ExtendedCost,'') ='' OR CAST(ExtendedCostType AS VARCHAR(10)) LIKE '%' + CAST(@ExtendedCost AS VARCHAR(10))+ '%') AND
		   (ISNULL(@ReplacementDate,'') ='' OR Cast(ReplacementDate AS DATE) = CAST(@ReplacementDate AS DATE)) AND 
		   (ISNULL(@VendorRMADetailStatus,'') ='' OR VendorRMADetailStatusType LIKE  '%'+@VendorRMADetailStatus+'%') AND  	   
		   (ISNULL(@RefundedRef,'') ='' OR RefundedRef LIKE '%'+@RefundedRef+'%') AND  
		   (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+@VendorName+'%') AND  
		   (ISNULL(@QtyShipped,'') ='' OR CAST(QtyShipped AS varchar(10)) LIKE '%' + CAST(@QtyShipped AS VARCHAR(10))+ '%') AND
		   (ISNULL(@Memo,'') ='' OR MemoType LIKE '%'+@Memo+'%') AND  
		   (ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%'+ @CreatedBy+'%') AND  
		   (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%'+ @UpdatedBy+'%') AND  
		   (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE)=CAST(@CreatedDate AS DATE)) AND  
		   (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE)=CAST(@UpdatedDate AS DATE)) AND
		   (ISNULL(@Condition,'') ='' OR Condition LIKE '%'+@Condition+'%') 
		   )  
		   ))
		  -- Materialize once instead of re-running the grouped query for COUNT and again for the page.
		  SELECT * INTO #SummaryResult FROM FinalResult;

		  SELECT @Count = COUNT(VendorRMAId) FROM #SummaryResult;

		  SELECT VendorRMAId, VendorId, VendorName, VendorCode, RMANumber, OpenDate, VendorRMAStatusId, RMAStatusType, ReasonType, ShippedDate, ShipRefrence,
		  ReferenceNumberType, PartNumberType, StockLineIdType, SerialNumberType, StockLineNumberType, PartDescriptionType, QtyType, UnitCostType ,ExtendedCostType,  ReferenceIdType,
		  ReplacementDate, ReceiverID, RefundedDate, RefundedRef,MemoType, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, VendorCreditMemoId,
		  VendorRMADetailStatusType, VendorRMANumber, ModuleId, QtyShipped, VendorRMADetailId,QuantityReceivedType , Condition , @Count AS NumberOfItems FROM #SummaryResult

		  ORDER BY    
		  CASE WHEN (@SortOrder=1 AND @SortColumn='VENDORRMAID')  THEN VendorRMAId END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='RMANUMBER')  THEN RMANumber END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='OPENDATE')  THEN OpenDate END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='RMASTATUSTYPE')  THEN RMAStatusType END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='REASONTYPE')  THEN ReasonType END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='SHIPPEDDATE')  THEN ShippedDate END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='SHIPREFRENCE')  THEN ShipRefrence END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='REFERENCENUMBERTYPE')  THEN ReferenceNumberType END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='SERIALNUMBERTYPE')  THEN SerialNumberType END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='STOCKLINENUMBERTYPE')  THEN StockLineNumberType END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='QTYTYPE')  THEN QtyType END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='UNITCOSTTYPE')  THEN UnitCostType END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='EXTENDEDCOSTTYPE')  THEN ExtendedCostType END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='REPLACEMENTDATE')  THEN ReplacementDate END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='RECEIVERID')  THEN ReceiverID END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='REFUNDEDDATE')  THEN RefundedDate END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='REFUNDEDREF')  THEN RefundedRef END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='MEMOTYPE')  THEN MemoType END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,   	  
		   CASE WHEN (@SortOrder=1 AND @SortColumn='Condition')  THEN Condition END ASC,

		  CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORRMAID')  THEN VendorRMAId END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='RMANUMBER')  THEN RMANumber END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='OPENDATE')  THEN OpenDate END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='RMASTATUSTYPE')  THEN RMAStatusType END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='REASONTYPE')  THEN ReasonType END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='SHIPPEDDATE')  THEN ShippedDate END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='SHIPREFRENCE')  THEN ShipRefrence END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='REFERENCENUMBERTYPE')  THEN ReferenceNumberType END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='SERIALNUMBERTYPE')  THEN SerialNumberType END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='STOCKLINENUMBERTYPE')  THEN StockLineNumberType END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='QTYTYPE')  THEN QtyType END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UNITCOSTTYPE')  THEN UnitCostType END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='EXTENDEDCOSTTYPE')  THEN ExtendedCostType END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='REPLACEMENTDATE')  THEN ReplacementDate END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='RECEIVERID')  THEN ReceiverID END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='REFUNDEDDATE')  THEN RefundedDate END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='REFUNDEDREF')  THEN RefundedRef END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='MEMOTYPE')  THEN MemoType END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
		  VendorRMAId DESC -- tie-breaker keeps paging stable
		 OFFSET @RecordFrom ROWS   
		 FETCH NEXT @PageSize ROWS ONLY  
	END
   END  
   --COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    --ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_VendorRMA_GetVendorRMAList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + ISNULL(CAST(@PageNumber AS VARCHAR(20)), '') + ''''  
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