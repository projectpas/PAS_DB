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
			RMAD.[Qty] AS 'QtyType',
			RMAD.[UnitCost] AS 'UnitCostType',
			RMAD.[ExtendedCost] AS 'ExtendedCostType',
			RMAD.[ReferenceId] AS 'ReferenceIdType',
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
			RMS.QtyShipped,
			RMAD.VendorRMADetailId,
			RQTY.QuantityReceived,
			SL.Condition as 'Condition'
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
		OUTER APPLY(
			SELECT ISNULL(SUM(ISNULL(SL.[Quantity],0)),0) AS QuantityReceived 
			FROM [dbo].[Stockline] SL WITH(NOLOCK) 
			WHERE SL.[VendorRMAId] = RMA.[VendorRMAId] 
			  AND SL.[VendorRMADetailId] = RMAD.[VendorRMADetailId] 
			  AND SL.[IsParent] = 1 
			  AND SL.[IsDeleted] = 0		
		) AS RQTY

		WHERE RMA.[MasterCompanyId] = @MasterCompanyId AND (@StatusType IS NULL OR RMA.VendorRMAStatusId = @StatusType )  --RMA.VendorRMAStatusId = CASE WHEN @StatusType = 0 THEN RMA.VendorRMAStatusId  ELSE @StatusType END --AND RMA.[VendorRMAId] = CASE WHEN @VendorRMAId != 0 and @VendorRMAId is not null THEN @VendorRMAId ELSE RMAD.[VendorRMAId] END
		),
    FinalResult AS (  
    SELECT VendorRMAId, VendorId, VendorName, VendorCode, RMANumber, OpenDate, VendorRMAStatusId, RMAStatusType, VendorRMAReturnReasonId, ReasonType, ShippedDate, ShipRefrence,   
      ReferenceNumberType, IsPORO, ItemMasterId, PartNumberType, StockLineIdType, SerialNumberType, StockLineNumberType, PartDescriptionType, QtyType, UnitCostType, ExtendedCostType,  ReferenceIdType, 
      ReplacementDate, ReceiverID, RefundedDate, RefundedRef, MemoType, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, VendorCreditMemoId, VendorRMADetailStatus, 
	  VendorRMANumber, ModuleId, QtyShipped, VendorRMADetailId,Condition, QuantityReceived FROM Result  
    WHERE  (  
     (@GlobalFilter <>'' AND ((RMANumber LIKE '%' +@GlobalFilter+'%' ) OR   
       (OpenDate LIKE '%' +@GlobalFilter+'%') OR  
       (RMAStatusType LIKE '%' +@GlobalFilter+'%') OR  
       (ReasonType LIKE '%' +@GlobalFilter+'%') OR  
       (ShippedDate LIKE '%' +@GlobalFilter+'%') OR  
       (ShipRefrence LIKE '%'+@GlobalFilter+'%') OR  
       (ReferenceNumberType LIKE '%' +@GlobalFilter+'%') OR  
       (PartNumberType LIKE '%' +@GlobalFilter+'%') OR  
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
       (ISNULL(@ShippedDate,'') ='' OR CAST(ShippedDate AS DATE) = CAST(@ShippedDate AS DATE)) AND
	   (ISNULL(@ShipRefrence,'') ='' OR ShipRefrence LIKE '%'+@ShipRefrence+'%') AND
       (ISNULL(@ReferenceNumber,'') ='' OR ReferenceNumberType LIKE '%'+@ReferenceNumber+'%') AND  
       (ISNULL(@Partnumber,'') ='' OR PartNumberType LIKE '%'+ @Partnumber+'%') AND  
       (ISNULL(@SerialNumber,'') ='' OR SerialNumberType LIKE '%'+ @SerialNumber+'%') AND  
       (ISNULL(@StockLineNumber,'') ='' OR StockLineNumberType LIKE '%'+ @StockLineNumber +'%') AND  
       (ISNULL(@PartDescription,'') ='' OR PartDescriptionType LIKE '%'+ @PartDescription +'%') AND  
       (ISNULL(@Qty,'') ='' OR QtyType = @Qty ) AND  
	   (ISNULL(@UnitCost,'') ='' OR CAST(UnitCostType AS VARCHAR(10)) LIKE '%' + CAST(@UnitCost AS VARCHAR(10))+ '%') AND
	   (ISNULL(@ExtendedCost,'') ='' OR CAST(ExtendedCostType AS VARCHAR(10)) LIKE '%' + CAST(@ExtendedCost AS VARCHAR(10))+ '%') AND
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
       )),  
      ResultCount AS (Select COUNT(VendorRMAId) AS NumberOfItems FROM FinalResult)  

      SELECT VendorRMAId, VendorId, VendorName, VendorCode, RMANumber, OpenDate, VendorRMAStatusId, RMAStatusType, VendorRMAReturnReasonId, ReasonType, ShippedDate, ShipRefrence,   
      ReferenceNumberType, IsPORO, ItemMasterId, PartNumberType, StockLineIdType, SerialNumberType, StockLineNumberType, PartDescriptionType, QtyType, UnitCostType, ExtendedCostType,  ReferenceIdType, 
      ReplacementDate, ReceiverID, RefundedDate, RefundedRef, MemoType, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, VendorCreditMemoId, VendorRMADetailStatus 
	  VendorRMANumber, ModuleId, QtyShipped, VendorRMADetailId,QuantityReceived, Condition, NumberOfItems FROM FinalResult, ResultCount  
  
      ORDER BY    
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
	  CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC
     OFFSET @RecordFrom ROWS   
     FETCH NEXT @PageSize ROWS ONLY  
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
				0 AS VendorRMADetailId
				--RQTY.QuantityReceived
			FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
			INNER JOIN [DBO].[Vendor] V WITH (NOLOCK) ON RMA.VendorId = V.VendorId
			LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.[VendorRMAId] = RMAD.[VendorRMAId]
			LEFT JOIN [DBO].[VendorCreditMemo] VCM WITH (NOLOCK) ON VCM.VendorRMAId = RMA.VendorRMAId
			--OUTER APPLY(
			--SELECT ISNULL(SUM(ISNULL(SL.[Quantity],0)),0) AS QuantityReceived 
			--	FROM [dbo].[Stockline] SL WITH(NOLOCK) 
			--	WHERE SL.[VendorRMAId] = RMA.[VendorRMAId] 
			--	  AND SL.[VendorRMADetailId] = RMAD.[VendorRMADetailId] 
			--	  AND SL.[IsParent] = 1 
			--	  AND SL.[IsDeleted] = 0		
			--) AS RQTY
			WHERE RMA.[MasterCompanyId] = @MasterCompanyId AND (@StatusType IS NULL OR RMA.VendorRMAStatusId = @StatusType) --AND RMAD.VendorRMAId IS NOT NULL AND RMA.[VendorRMAId] = CASE WHEN @VendorRMAId != 0 and @VendorRMAId is not null THEN @VendorRMAId ELSE RMAD.[VendorRMAId] END
			)
			,RQTYCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.QuantityReceived END) AS 'QuantityReceivedType',A.QuantityReceived 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT CASE WHEN CAST(ISNULL(SUM(ISNULL(SL.[Quantity],0)),0) AS varchar(100)) != '' THEN ',' ELSE '' END + CAST(ISNULL(SUM(ISNULL(SL.[Quantity],0)),0) AS VARCHAR(100))
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  LEFT JOIN [DBO].[Stockline] SL WITH (NOLOCK) ON RMAD_A.VendorRMADetailId = SL.VendorRMADetailId 
							  AND SL.[VendorRMAId] = RMA.[VendorRMAId] AND SL.[IsParent] = 1 AND SL.[IsDeleted] = 0
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') QuantityReceived
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.QuantityReceived
			)
			,PartCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.PartNumber END) AS 'PartNumberType',A.PartNumber 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT CASE WHEN P.partnumber != '' THEN ',' ELSE '' END + P.partnumber
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  LEFT JOIN [DBO].[ItemMaster] P WITH (NOLOCK) ON RMAD_A.ItemMasterId = P.ItemMasterId
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') PartNumber
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.PartNumber
			)
			,PartDescCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.PartDescription END) AS 'PartDescriptionType',A.PartDescription 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT CASE WHEN P.PartDescription != '' THEN ',' ELSE '' END + P.PartDescription
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  LEFT JOIN [DBO].[ItemMaster] P WITH (NOLOCK) ON RMAD_A.ItemMasterId = P.ItemMasterId
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') PartDescription
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				Group By RMAD.VendorRMAId, A.PartDescription
			)
			,SNumberCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.SerialNumber END) AS 'SerialNumberType',A.SerialNumber 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT CASE WHEN RMAD_A.SerialNumber != '' THEN ',' ELSE '' END + RMAD_A.SerialNumber
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') SerialNumber
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.SerialNumber
			)
			,RefrenceCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.ReferenceNumber END) AS 'ReferenceNumberType',A.ReferenceNumber 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) On RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT ',' + (CASE WHEN SL.[PurchaseOrderId] > 0 THEN PO.[PurchaseOrderNumber] WHEN SL.[RepairOrderId] > 0 THEN RO.[RepairOrderNumber] ELSE '' END)
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  LEFT JOIN [DBO].[Stockline] SL WITH (NOLOCK) ON RMAD_A.StockLineId = SL.StockLineId
							  LEFT JOIN [DBO].[PurchaseOrder] PO WITH (NOLOCK) ON SL.[PurchaseOrderId] = PO.[PurchaseOrderId]
							  LEFT JOIN [DBO].[RepairOrder] RO WITH (NOLOCK) ON SL.[RepairOrderId] = RO.[RepairOrderId]
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') ReferenceNumber
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.ReferenceNumber
			)
			,StockIdCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.StockLineId END) AS 'StockLineIdType',A.StockLineId 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT ',' + CAST(SL.StockLineId AS VARCHAR(100))
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  LEFT JOIN [DBO].[Stockline] SL WITH (NOLOCK) ON RMAD_A.StockLineId = SL.StockLineId							
							   Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') StockLineId
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.StockLineId
			)
			,StockNumCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.StockLineNumber END) AS 'StockLineNumberType',A.StockLineNumber 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT CASE WHEN SL.StockLineNumber != '' THEN ',' ELSE '' END + SL.StockLineNumber
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  LEFT JOIN [DBO].[Stockline] SL WITH (NOLOCK) ON RMAD_A.StockLineId = SL.StockLineId							 
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') StockLineNumber
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.StockLineNumber
			)

			,StockCondCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.StockLineNumber END) AS 'Condition',A.StockLineNumber 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT CASE WHEN SL.Condition != '' THEN ',' ELSE '' END + SL.Condition
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  LEFT JOIN [DBO].[Stockline] SL WITH (NOLOCK) ON RMAD_A.StockLineId = SL.StockLineId							 
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') StockLineNumber
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.StockLineNumber
			),

			StatusCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.VendorRMAStatus END) AS 'RMAStatusType',A.VendorRMAStatus 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT CASE WHEN VS.VendorRMAStatus != '' THEN ',' ELSE '' END + VS.VendorRMAStatus
							  FROM [DBO].[VendorRMA] RMAD_A
							   LEFT JOIN [DBO].[VendorRMAStatus] VS WITH (NOLOCK) ON RMAD_A.VendorRMAStatusId = VS.VendorRMAStatusId
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') VendorRMAStatus
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.VendorRMAStatus
			),
			ReasonCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.VendorRMAReturnReason END) AS 'ReasonType',A.VendorRMAReturnReason 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT CASE WHEN RMAR.Reason != '' THEN ',' ELSE '' END + RMAR.Reason
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  LEFT JOIN [DBO].[VendorRMAReturnReason] RMAR WITH (NOLOCK) ON RMAD_A.[VendorRMAReturnReasonId] = RMAR.[VendorRMAReturnReasonId]
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') VendorRMAReturnReason
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.VendorRMAReturnReason
			),
			QtyCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.Qty END) AS 'QtyType',A.Qty 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) On RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT ',' + CAST(RMAD_A.Qty AS VARCHAR(100))
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') Qty
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.Qty
			),
			UCostCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.UnitCost END)  AS 'UnitCostType',A.UnitCost 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT ',' + CAST(RMAD_A.UnitCost AS VARCHAR(100)) --CONVERT(VARCHAR, CONVERT(DECIMAL, RMAD_A.UnitCost))
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') UnitCost
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.UnitCost
			),
			ECostCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.ExtendedCost END)  AS 'ExtendedCostType',A.ExtendedCost 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT ',' + CAST(RMAD_A.ExtendedCost AS VARCHAR(100))
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') ExtendedCost
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.ExtendedCost
			),
			RefrenceIdCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.ReferenceId END)  AS 'ReferenceIdType',A.ReferenceId 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT ',' + CAST(RMAD_A.ReferenceId AS VARCHAR(100))
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') ReferenceId
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.ReferenceId
			),
			NotesCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.Memo END) AS 'MemoType',A.Memo 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					   STUFF((SELECT CASE WHEN RMAD_A.Notes != '' THEN ',' ELSE '' END + (select [dbo].[fn_parsehtml] (RMAD_A.Notes))
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') Memo
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.Memo
			),
			RMAStatusCTE AS(
				SELECT RMAD.VendorRMAId,(CASE WHEN COUNT(RMAD.VendorRMAId) > 1 THEN 'Multiple' ELSE A.VendorRMADetailStatus END) AS 'VendorRMADetailStatusType',A.VendorRMADetailStatus 
				FROM [DBO].[VendorRMA] RMA WITH (NOLOCK)
				LEFT JOIN [DBO].[VendorRMADetail] RMAD WITH (NOLOCK) ON RMA.VendorRMAId=RMAD.VendorRMAId 
				OUTER APPLY(
					SELECT 
					  STUFF((SELECT ',' + VS.VendorRMAStatus
							  FROM [DBO].[VendorRMADetail] RMAD_A
							  LEFT JOIN [DBO].[VendorRMAStatus] VS WITH (NOLOCK) ON RMAD_A.VendorRMAStatusId = VS.VendorRMAStatusId
							  Where RMAD.VendorRMAId = RMAD_A.VendorRMAId
							  FOR XML PATH('')), 1, 1, '') VendorRMADetailStatus
				) A 
				WHERE RMAD.VendorRMAId IS NOT NULL
				GROUP BY RMAD.VendorRMAId, A.VendorRMADetailStatus
			),
		FinalResult AS (  
		SELECT M.VendorRMAId, VendorId, VendorName, VendorCode, RMANumber, OpenDate, VendorRMAStatusId, ST.VendorRMAStatus, ST.RMAStatusType,  RST.VendorRMAReturnReason, RST.ReasonType ,ShippedDate, ShipRefrence,   
		  RT.ReferenceNumber, RT.ReferenceNumberType, PT.Partnumber, PT.PartNumberType, STKT.StockLineId, STKT.StockLineIdType, SNT.SerialNumber, SNT.SerialNumberType, STNT.StockLineNumber, STNT.StockLineNumberType, PDT.PartDescription, PDT.PartDescriptionType, QT.Qty, QT.QtyType, UCT.UnitCost, UCT.UnitCostType, ECT.ExtendedCost, ECT.ExtendedCostType,  RIT.ReferenceId, RIT.ReferenceIdType, 
		  ReplacementDate, ReceiverID, RefundedDate, RefundedRef, NT.Memo, Nt.MemoType, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, 
		  VendorCreditMemoId, RMAS.VendorRMADetailStatus, RMAS.VendorRMADetailStatusType, VendorRMANumber, ModuleId, QtyShipped, VendorRMADetailId,QTY.QuantityReceivedType,QTY.QuantityReceived , Condition FROM Result M
		  LEFT JOIN RQTYCTE QTY ON M.VendorRMAId=QTY.VendorRMAId
		  LEFT JOIN PartCTE PT ON M.VendorRMAId=PT.VendorRMAId
		  LEFT JOIN PartDescCTE PDT ON M.VendorRMAId=PDT.VendorRMAId
		  LEFT JOIN SNumberCTE SNT ON M.VendorRMAId=SNT.VendorRMAId
		  LEFT JOIN RefrenceCTE RT ON M.VendorRMAId=RT.VendorRMAId
		  LEFT JOIN StockIdCTE STKT ON M.VendorRMAId=STKT.VendorRMAId
		  LEFT JOIN StockNumCTE STNT ON M.VendorRMAId=STNT.VendorRMAId
		  LEFT JOIN StatusCTE ST ON M.VendorRMAId=ST.VendorRMAId
		  LEFT JOIN ReasonCTE RST ON M.VendorRMAId=RST.VendorRMAId
		  LEFT JOIN QtyCTE QT ON M.VendorRMAId=QT.VendorRMAId
		  LEFT JOIN UCostCTE UCT ON M.VendorRMAId=UCT.VendorRMAId
		  LEFT JOIN ECostCTE ECT ON M.VendorRMAId=ECT.VendorRMAId
		  LEFT JOIN RefrenceIdCTE RIT ON M.VendorRMAId=RIT.VendorRMAId
		  LEFT JOIN NotesCTE NT ON M.VendorRMAId=NT.VendorRMAId
		  LEFT JOIN RMAStatusCTE RMAS ON M.VendorRMAId=RMAS.VendorRMAId
		  LEFT JOIN StockCondCTE SC ON M.VendorRMAId=SC.VendorRMAId
		WHERE (  
		 (@GlobalFilter <>'' AND ((RMANumber LIKE '%' +@GlobalFilter+'%' ) OR   
		   (OpenDate LIKE '%' +@GlobalFilter+'%') OR  
		   (ST.VendorRMAStatus LIKE '%' +@GlobalFilter+'%') OR  
		   (RST.VendorRMAReturnReason LIKE '%' +@GlobalFilter+'%') OR  
		   (ShippedDate LIKE '%' +@GlobalFilter+'%') OR  
		   (ShipRefrence LIKE '%'+@GlobalFilter+'%') OR  
		   (RT.ReferenceNumber LIKE '%' +@GlobalFilter+'%') OR  
		   (PT.Partnumber LIKE '%' +@GlobalFilter+'%') OR  
		   (SNT.SerialNumber LIKE '%' +@GlobalFilter+'%') OR  
		   (STNT.StockLineNumber LIKE '%' +@GlobalFilter+'%') OR  
		   (PDT.PartDescription LIKE '%' +@GlobalFilter+'%') OR  
		   (QT.Qty LIKE '%' +@GlobalFilter+'%') OR  
		   (CAST(UCT.UnitCost AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR  
		   (CAST(ECT.ExtendedCost AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR 
		   (ReplacementDate LIKE '%' +@GlobalFilter+'%') OR
		   (ReceiverID LIKE '%' +@GlobalFilter+'%') OR  
		   (RefundedDate LIKE '%' +@GlobalFilter+'%') OR  
		   (RefundedRef LIKE '%' +@GlobalFilter+'%') OR  
		   (VendorName LIKE '%' +@GlobalFilter+'%') OR  
		   (NT.Memo LIKE '%' +@GlobalFilter+'%') OR  
		   (CreatedDate LIKE '%' +@GlobalFilter+'%') OR  
		   (UpdatedDate LIKE '%' +@GlobalFilter+'%') OR
		   (Condition LIKE '%' +@GlobalFilter+'%') 
		   ))  
		   OR     
		   (@GlobalFilter='' AND (ISNULL(@RMANumber,'') ='' OR RMANumber LIKE  '%'+ @RMANumber+'%') AND   
		   (ISNULL(@OpenDate,'') ='' OR CAST(OpenDate AS DATE) = CAST(@OpenDate AS DATE)) AND  
		   (ISNULL(@VendorRMAStatus,'') ='' OR ST.VendorRMAStatus LIKE  '%'+@VendorRMAStatus+'%') AND  
		   (ISNULL(@VendorRMAReturnReason,'') ='' OR RST.VendorRMAReturnReason LIKE '%'+@VendorRMAReturnReason+'%') AND  
		   (ISNULL(@ShippedDate,'') ='' OR Cast(ShippedDate AS DATE) = CAST(@ShippedDate AS DATE)) AND
		   (ISNULL(@ReferenceNumber,'') ='' OR RT.ReferenceNumber LIKE '%'+@ReferenceNumber+'%') AND  
		   (ISNULL(@Partnumber,'') ='' OR PT.Partnumber LIKE '%'+ @Partnumber+'%') AND  
		   (ISNULL(@SerialNumber,'') ='' OR SNT.SerialNumber LIKE '%'+ @SerialNumber+'%') AND  
		   (ISNULL(@StockLineNumber,'') ='' OR STNT.StockLineNumber LIKE '%'+ @StockLineNumber +'%') AND  
		   (ISNULL(@PartDescription,'') ='' OR PDT.PartDescription LIKE '%'+ @PartDescription +'%') AND  
		   (ISNULL(@Qty,'') ='' OR QT.QtyType = @Qty ) AND  
		   (ISNULL(@UnitCost,'') ='' OR CAST(UCT.UnitCostType AS VARCHAR(10)) LIKE '%' + CAST(@UnitCost AS VARCHAR(10))+ '%') AND
		   (ISNULL(@ExtendedCost,'') ='' OR CAST(ExtendedCostType AS VARCHAR(10)) LIKE '%' + CAST(@ExtendedCost AS VARCHAR(10))+ '%') AND
		   (ISNULL(@ReplacementDate,'') ='' OR Cast(ReplacementDate AS DATE) = CAST(@ReplacementDate AS DATE)) AND 
		   (ISNULL(@VendorRMADetailStatus,'') ='' OR VendorRMADetailStatusType LIKE  '%'+@VendorRMADetailStatus+'%') AND  	   
		   (ISNULL(@RefundedRef,'') ='' OR RefundedRef LIKE '%'+@RefundedRef+'%') AND  
		   (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+@VendorName+'%') AND  
		   (ISNULL(@QtyShipped,'') ='' OR CAST(QtyShipped AS varchar(10)) LIKE '%' + CAST(@QtyShipped AS VARCHAR(10))+ '%') AND
		   (ISNULL(@Memo,'') ='' OR NT.Memo LIKE '%'+@Memo+'%') AND  
		   (ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%'+ @CreatedBy+'%') AND  
		   (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%'+ @UpdatedBy+'%') AND  
		   (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE)=CAST(@CreatedDate AS DATE)) AND  
		   (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE)=CAST(@UpdatedDate AS DATE)) AND
		   (ISNULL(@Condition,'') ='' OR SC.Condition LIKE '%'+@Condition+'%') 
		   )  
		   )),  
		  ResultCount AS (SELECT COUNT(VendorRMAId) AS NumberOfItems FROM FinalResult)  

		  SELECT VendorRMAId, VendorId, VendorName, VendorCode, RMANumber, OpenDate, VendorRMAStatusId, VendorRMAStatus, RMAStatusType, VendorRMAReturnReason, ReasonType, ShippedDate, ShipRefrence,   
		  ReferenceNumber, ReferenceNumberType, Partnumber, PartNumberType, StockLineId, StockLineIdType, SerialNumber, SerialNumberType, StockLineNumber, StockLineNumberType, PartDescription, PartDescriptionType, Qty, QtyType, UnitCost, UnitCostType , ExtendedCost, ExtendedCostType,  ReferenceId, ReferenceIdType, 
		  ReplacementDate, ReceiverID, RefundedDate, RefundedRef, Memo,  MemoType, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, VendorCreditMemoId, 
		  VendorRMADetailStatus,VendorRMADetailStatusType, VendorRMANumber, ModuleId, QtyShipped, VendorRMADetailId,QuantityReceived,QuantityReceivedType , Condition , NumberOfItems FROM FinalResult, ResultCount  
  
		  ORDER BY    
		  CASE WHEN (@SortOrder=1 AND @SortColumn='VENDORRMAID')  THEN VendorRMAId END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='RMANUMBER')  THEN RMANumber END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='OPENDATE')  THEN OpenDate END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='VENDORRMASTATUS')  THEN VendorRMAStatus END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='VENDORRMARETURNREASON')  THEN VendorRMAReturnReason END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='SHIPPEDDATE')  THEN ShippedDate END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='SHIPREFRENCE')  THEN ShipRefrence END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='REFERENCENUMBER')  THEN ReferenceNumber END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='PARTNUMBER')  THEN Partnumber END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='SERIALNUMBER')  THEN SerialNumber END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='STOCKLINENUMBER')  THEN StockLineNumber END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='PARTDESCRIPTION')  THEN PartDescription END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='QTY')  THEN Qty END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='UNITCOST')  THEN UnitCost END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='EXTENDEDCOST')  THEN ExtendedCost END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='REPLACEMENTDATE')  THEN ReplacementDate END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='RECEIVERID')  THEN ReceiverID END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='REFUNDEDDATE')  THEN RefundedDate END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='REFUNDEDREF')  THEN RefundedRef END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='MEMO')  THEN Memo END ASC, 
		  CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
		  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,   	  
		   CASE WHEN (@SortOrder=1 AND @SortColumn='Condition')  THEN UpdatedBy END ASC,

		  CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORRMAID')  THEN VendorRMAId END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='RMANUMBER')  THEN RMANumber END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='OPENDATE')  THEN OpenDate END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORRMASTATUS')  THEN VendorRMAStatus END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORRMARETURNREASON')  THEN VendorRMAReturnReason END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='SHIPPEDDATE')  THEN ShippedDate END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='SHIPREFRENCE')  THEN ShipRefrence END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='REFERENCENUMBER')  THEN ReferenceNumber END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBER')  THEN Partnumber END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='SERIALNUMBER')  THEN SerialNumber END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='STOCKLINENUMBER')  THEN StockLineNumber END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTDESCRIPTION')  THEN PartDescription END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='QTY')  THEN Qty END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UNITCOST')  THEN UnitCost END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='EXTENDEDCOST')  THEN ExtendedCost END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='REPLACEMENTDATE')  THEN ReplacementDate END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='RECEIVERID')  THEN ReceiverID END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='REFUNDEDDATE')  THEN RefundedDate END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='REFUNDEDREF')  THEN RefundedRef END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='MEMO')  THEN Memo END DESC, 
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
		  CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN UpdatedBy END DESC
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