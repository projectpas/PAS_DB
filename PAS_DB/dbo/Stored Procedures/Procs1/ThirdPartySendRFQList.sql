
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.ThirdPartySendRFQList   (source: PAS_DB/dbo/Stored Procedures/Procs1/ThirdPartySendRFQList.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [ThirdPartySendRFQList]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Third Party Send RFQ List
 ** Date:   14/02/2024
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    14/02/2024   Rajesh Gami     Created
	2    24-07-2025   Amit Ghediya    MOdify for get RFQ part is in our inventory or not (ItemMasterId)
	3    08-10-2025   Devendra Shekh  Added Params And Fields For : RFQSentDate, VendorName, VendorRFQReferenceNumber, VendorResponseReceived, VendorResponseDate
	4    08-10-2025   Amit Ghediya    add po vendor param
	5    09-10-2025   Devendra Shekh  Added ReferenceId, ModuleId
	6    14-10-2025   Devendra Shekh  Added VendorRFQPurchaseOrderNumber, RFQReferenceId, RFQModuleId
	7    04-11-2025   Devendra Shekh  Getting VendorRFQPurchaseOrderNumber, RFQReferenceId, RFQModuleId Based On [PurChaseOrder]-[VendorRFQPurchaseOrderPart]
	8    04-12-2025   Devendra Shekh  Modified to DateTime For rfqSentDate, vendorResponseDate
	9    03-02-2026   Vishal Suthar   Fixed ItemMaster duplicate issue with same partnumber with different description we have in PAS
	10    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

**************************************************************
**************************************************************/
CREATE     PROCEDURE [dbo].[ThirdPartySendRFQList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@IntegrationPortalId int = NULL,
@IntegrationRFQStatusId int = NULL,
@Status varchar(50) = NULL,
@RFQId varchar(50) = NULL,
@PortalRFQId varchar(50) = NULL,
@Name varchar(100) = NULL,
@IntegrationRFQTypeId int =NULL,
@TypeName varchar(50) = NULL,
@IntegrationPortal varchar(50) = NULL,
@Priority varchar(50) = NULL,
@RequestedQty int = NULL,
@QuoteWithinDays int = NULL,
@DeliverByDate datetime2 = NULL,
@PreparedBy varchar(50) = NULL,
@PartNumber varchar(70) = NULL,
@AltPartNumber varchar(70) = NULL,
@Exchange varchar(70) = NULL,
@Description varchar(max) = NULL,
@Qty int = NULL,
@Condition varchar(20) = NULL,
@IsEmail bit = NULL,
@IsFax bit = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL,
@MasterCompanyId bigint = NULL,
@StatusFilter varchar(50) = NULL,
@UserEmployeeId BIGINT = NULL,
@RFQSentDate datetime2 = NULL,
@VendorName varchar(150) = NULL,
@vendorRFQReferenceNumber varchar(200) = NULL,
@VendorResponseReceived varchar(50) = NULL,
@VendorResponseDate datetime2 = NULL,
@VendorNames varchar(100) = NULL,
@VendorNamesDisplay varchar(100) = NULL,
@PONumber varchar(100) = NULL,
@VendorRFQPurchaseOrderNumber varchar(100) = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY

		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		DECLARE @PoModuleId BIGINT = 0, @RFQPOModuleId BIGINT = 0;

		SELECT @PoModuleId = [ModuleId] FROM [Dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'PurchaseOrder';
		SELECT @RFQPOModuleId = [ModuleId] FROM [Dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'VendorRFQPurchaseOrder';

		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn = (CASE WHEN UPPER(@SortColumn) = UPPER('CreatedByFilter') THEN 'CreatedBy' ELSE @SortColumn END)
			Set @SortColumn=UPPER(@SortColumn)
		END	
		IF(@IntegrationPortalId = 0)
		BEGIN
			SET @IntegrationPortalId = NULL
		END
		--IF(@IntegrationRFQStatusId=0)
		--BEGIN
		--	SET @IsActive=0;
		--END
		--ELSE IF(@IntegrationRFQStatusId=1)
		--BEGIN
		--	SET @IsActive=1;
		--END
		--ELSE
		--BEGIN
		--	SET @IsActive=NULL;
		--END
		SET @IsActive=1
		SET @IsDeleted =0
		IF(@IntegrationRFQStatusId=0)
		BEGIN
			SET @IntegrationRFQStatusId = NULL
		END
		IF(@IntegrationRFQStatusId=0 AND @Status = 'All')
		BEGIN
			SET @Status = NULL
		END
		IF(@IntegrationRFQTypeId = 0)
		BEGIN
			SET @IntegrationRFQTypeId = NULL;
		END

		/* --------------START: Get the timzone and UTC offset -------------- */
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(400) = '', @BaseUtcOffsetSec BIGINT = 0;
		SELECT 	@CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description] )
		FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @UserEmployeeId AND E.MasterCompanyId = @MasterCompanyId;	
				
		SELECT TOP 1 @BaseUtcOffsetSec = BaseUtcOffsetSec FROM dbo.TimeZone WITH(NOLOCK) WHERE [Description] = @CurrntEmpTimeZoneDesc
		/* -------------- END: Get the timzone and UTC offset -------------- */
		 
		;WITH
		VendorRFQPartResult AS (
			SELECT [ILSRFQDetailId], [MasterCompanyId], MIN([CreatedDate]) AS [CreatedDate], MIN([ReferenceNumber]) AS [ReferenceNumber] 
			FROM [DBO].[VendorRFQPart] WITH(NOLOCK)
			WHERE ISNULL([IsDeleted], 0) = 0 AND ISNULL([IsActive], 0) = 1 AND [MasterCompanyId] = @MasterCompanyId  
			GROUP BY [ILSRFQDetailId], [MasterCompanyId]
		),
		VendorRFQReferenceResult AS (
			SELECT * FROM (
				SELECT [ILSRFQDetailId], [MasterCompanyId], [ReferenceId], [ModuleId]
				,COUNT(*) OVER (PARTITION BY [ILSRFQDetailId], [ModuleId]) AS RefModCount
				FROM [DBO].[VendorRFQPart] WITH(NOLOCK)
				WHERE	ISNULL([IsDeleted], 0) = 0 AND ISNULL([IsActive], 0) = 1 AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([ModuleId], 0) = @PoModuleId
						GROUP BY [ILSRFQDetailId], [MasterCompanyId], [ReferenceId], [ModuleId]
				) AS t
			WHERE t.RefModCount = 1
		),
		RFQReferenceResult AS (
			SELECT * FROM (
				SELECT [ILSRFQDetailId], VRFQP.[MasterCompanyId], VPO.VendorRFQPurchaseOrderId AS RFQReferenceId, @RFQPOModuleId AS RFQModuleId
				,COUNT(*) OVER (PARTITION BY [ILSRFQDetailId], [ModuleId]) AS RefModCount
				FROM [DBO].[VendorRFQPart] VRFQP WITH(NOLOCK)
				INNER JOIN DBO.PurchaseOrder PO WITH(NOLOCK) ON PO.PurchaseOrderId = VRFQP.ReferenceId
				INNER JOIN DBO.VendorRFQPurchaseOrderPart VPOP WITH(NOLOCK) ON VPOP.PurchaseOrderId = PO.PurchaseOrderId
				INNER JOIN DBO.VendorRFQPurchaseOrder VPO WITH(NOLOCK) ON VPO.VendorRFQPurchaseOrderId = VPOP.VendorRFQPurchaseOrderId
				WHERE	ISNULL(VRFQP.[IsDeleted], 0) = 0 AND ISNULL(VRFQP.[IsActive], 0) = 1 AND VRFQP.[MasterCompanyId] = @MasterCompanyId AND ISNULL([ModuleId], 0) = @PoModuleId
						GROUP BY [ILSRFQDetailId], VRFQP.[MasterCompanyId], VPO.[VendorRFQPurchaseOrderId], [ModuleId]
				) AS t
			WHERE t.RefModCount = 1
		),
		Result AS(
				SELECT DISTINCT
					   part.ILSRFQPartId ILSRFQPartId,
					   tr.ThirdPartyRFQId,
					   ird.ILSRFQDetailId,
					   tr.RFQId,
					   tr.PortalRFQId,
					   tr.[Name] AS Name,
					   tr.IntegrationRFQTypeId IntegrationRFQTypeId,
					   tr.TypeName,
					   tr.IntegrationPortalId IntegrationPortalId,
					   tr.IntegrationPortal,
					   tr.IntegrationRFQStatusId IntegrationRFQStatusId,
					   tr.Status StatusFilter,
					   ISNULL(ird.PriorityId,0) PriorityId,
					   ird.Priority,
					   ISNULL(part.RequestedQty,0) RequestedQty,
					   ird.QuoteWithinDays QuoteWithinDays,
					   ird.DeliverByDate DeliverByDate,
					   ird.PreparedBy,
					   ISNULL(ird.AttachmentId,0) AttachmentId,
					   ird.DeliverToAddress,
					   ird.BuyerComment,					   
					   part.PartNumber,
					   part.AltPartNumber,
					   part.Exchange,
					   part.Description,
					   ISNULL(part.Qty,0) Qty,
					   part.Condition,
					   ISNULL(part.IsEmail,0) IsEmail,
					   ISNULL(part.IsFax,0) IsFax,
                       ISNULL(part.IsActive,0) IsActive,
                       ISNULL(part.IsDeleted,0) IsDeleted,
					   part.CreatedDate,
                       part.UpdatedDate,
					   Upper(part.CreatedBy) CreatedBy,
					   Upper(part.CreatedBy) CreatedByFilter,
                       Upper(part.UpdatedBy) UpdatedBy,
					   (CASE WHEN LOWER(TRIM(part.[PartNumber])) = LOWER(TRIM(IM.[partnumber])) THEN IM.[ItemMasterId] ELSE 0 END) ItemMasterId,
					   (CASE WHEN LOWER(TRIM(part.[AltPartNumber])) = LOWER(TRIM(IMSC.[partnumber])) THEN IMSC.[ItemMasterId] ELSE 0 END) AltItemMasterId,
					   CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, tr.CreatedDate)) AS 'RFQSentDate',
					   part.VendorName,
					   VRFQ.ReferenceNumber AS 'VendorRFQReferenceNumber',
					   CASE WHEN ISNULL(VRFQ.[ILSRFQDetailId], 0) > 0 THEN 'YES' ELSE 'NO' END AS 'VendorResponseReceived',
					   CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, VRFQ.[CreatedDate])) AS 'VendorResponseDate',
					   (
							SELECT STRING_AGG(VendorName, ', ')
							FROM (
								SELECT DISTINCT VRFQP.VendorName
								FROM DBO.VendorRFQPart VRFQP WITH(NOLOCK)
								WHERE VRFQP.ILSRFQDetailId = ird.ILSRFQDetailId
							) AS DistinctVendors
						) AS VendorNames,
						(
						SELECT 
							CASE 
								WHEN COUNT(DISTINCT PO.PurchaseOrderNumber) > 1 THEN 'MULTIPLE'
								ELSE MAX(PO.PurchaseOrderNumber)
							END
						FROM DBO.VendorRFQPart VRFQP WITH(NOLOCK)
						INNER JOIN DBO.PurchaseOrder PO WITH(NOLOCK) ON PO.PurchaseOrderId = VRFQP.ReferenceId
						WHERE VRFQP.ILSRFQDetailId = ird.ILSRFQDetailId AND VRFQP.moduleid = @PoModuleId
						) AS DisplayPONumber,
					   (
						SELECT STRING_AGG(PurchaseOrderNumber, ', ')
						FROM (
							SELECT DISTINCT PO.PurchaseOrderNumber
							FROM DBO.VendorRFQPart VRFQP WITH(NOLOCK)
							INNER JOIN DBO.PurchaseOrder PO WITH(NOLOCK) ON PO.PurchaseOrderId = VRFQP.ReferenceId
							WHERE VRFQP.ILSRFQDetailId = ird.ILSRFQDetailId AND VRFQP.ModuleId = @PoModuleId
						) AS DistinctVendors
					 ) AS PONumber,
					 (
						SELECT STRING_AGG(VendorRFQPurchaseOrderNumber, ', ')
						FROM (
							SELECT DISTINCT VPO.VendorRFQPurchaseOrderNumber
							FROM DBO.VendorRFQPart VRFQP WITH(NOLOCK)
							INNER JOIN DBO.PurchaseOrder PO WITH(NOLOCK) ON PO.PurchaseOrderId = VRFQP.ReferenceId
							INNER JOIN DBO.VendorRFQPurchaseOrderPart VPOP WITH(NOLOCK) ON VPOP.PurchaseOrderId = PO.PurchaseOrderId
							INNER JOIN DBO.VendorRFQPurchaseOrder VPO WITH(NOLOCK) ON VPO.VendorRFQPurchaseOrderId = VPOP.VendorRFQPurchaseOrderId
							WHERE VRFQP.ILSRFQDetailId = ird.ILSRFQDetailId AND VRFQP.ModuleId = @PoModuleId
						) AS DistinctVendors
					 ) AS VendorRFQPurchaseOrderNumber,
					 RR.ReferenceId,
					 RR.ModuleId,
					 RFQR.RFQReferenceId,
					 RFQR.RFQModuleId
			   FROM Dbo.ILSRFQPart part WITH(NOLOCK)
					INNER JOIN Dbo.ILSRFQDetail ird WITH(NOLOCK) on part.ILSRFQDetailId = ird.ILSRFQDetailId
					INNER JOIN Dbo.ThirdPartyRFQ tr WITH(NOLOCK)  on ird.ThirdPartyRFQId = tr.ThirdPartyRFQId
					LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON part.[PartNumber] = IM.[partnumber] AND part.Description = IM.PartDescription AND part.[MasterCompanyId] = IM.[MasterCompanyId]
					 AND ISNULL(IM.IsNonStock,0) = 0
					 LEFT JOIN dbo.ItemMaster IMSC WITH(NOLOCK) ON part.[AltPartNumber] = IMSC.[partnumber] AND IMSC.[IsActive] = 1 AND IMSC.[IsDeleted] = 0 AND part.[MasterCompanyId] = IMSC.[MasterCompanyId]
					 AND ISNULL(IMSC.IsNonStock,0) = 0
					  LEFT JOIN VendorRFQPartResult VRFQ ON VRFQ.ILSRFQDetailId = ird.ILSRFQDetailId AND VRFQ.[MasterCompanyId] = ird.[MasterCompanyId] 
					LEFT JOIN VendorRFQReferenceResult RR ON RR.ILSRFQDetailId = ird.ILSRFQDetailId AND RR.[MasterCompanyId] = ird.[MasterCompanyId] 
					LEFT JOIN RFQReferenceResult RFQR ON RFQR.ILSRFQDetailId = ird.ILSRFQDetailId AND RFQR.[MasterCompanyId] = ird.[MasterCompanyId] 
		 	  WHERE 
					((ISNULL(part.IsDeleted,0)= 0) ) AND 			     
					part.MasterCompanyId=@MasterCompanyId 
					AND (@IntegrationRFQTypeId IS NULL OR tr.IntegrationRFQTypeId = @IntegrationRFQTypeId)
					AND (@IntegrationRFQStatusId IS NULL OR tr.IntegrationRFQStatusId = @IntegrationRFQStatusId)
					AND (@IntegrationPortalId IS NULL OR tr.IntegrationPortalId = @IntegrationPortalId)
			), ResultCount AS(SELECT COUNT(ILSRFQPartId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND (([RFQId] LIKE '%' +@GlobalFilter+'%') OR
			        (PortalRFQId LIKE '%' +@GlobalFilter+'%') OR	
					(Name LIKE '%' +@GlobalFilter+'%') OR
					(TypeName LIKE '%' +@GlobalFilter+'%') OR
					(IntegrationPortal LIKE '%' +@GlobalFilter+'%') OR
					(StatusFilter LIKE '%' +@GlobalFilter+'%') OR
					(CAST(QuoteWithinDays AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR
					(DeliverByDate LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR   
					(VendorNames LIKE '%' +@GlobalFilter+'%') OR
					(PONumber LIKE '%' +@GlobalFilter+'%') OR
					(PartNumber LIKE '%' +@GlobalFilter+'%') OR   
					(AltPartNumber LIKE '%' +@GlobalFilter+'%') OR   
					(Exchange LIKE '%' +@GlobalFilter+'%') OR   
					(Description LIKE '%' +@GlobalFilter+'%') OR   
					(CAST(Qty AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR   
					(CAST(RequestedQty AS NVARCHAR(10)) LIKE '%' +@GlobalFilter+'%') OR   
					(Condition LIKE '%' +@GlobalFilter+'%') OR   
					(IsEmail LIKE '%' +@GlobalFilter+'%') OR   
					(IsFax LIKE '%' +@GlobalFilter+'%') OR
					(VendorName LIKE '%' +@GlobalFilter+'%') OR
					(VendorRFQReferenceNumber LIKE '%' +@GlobalFilter+'%') OR
					(VendorResponseReceived LIKE '%' +@GlobalFilter+'%') OR
					(VendorRFQPurchaseOrderNumber LIKE '%' +@GlobalFilter+'%') OR
					(CreatedDate like '%' + @GlobalFilter + '%') OR
					(UpdatedDate like '%' + @GlobalFilter + '%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@RFQId,'') ='' OR [RFQId] LIKE '%' + @RFQId+'%') AND
					(ISNULL(@PortalRFQId,'') ='' OR PortalRFQId LIKE '%' + @PortalRFQId + '%') AND	
					(ISNULL(@Name,'') ='' OR Name LIKE '%' + @Name + '%') AND	
					(ISNULL(@TypeName,'') ='' OR TypeName LIKE '%' + @TypeName + '%') AND
					(ISNULL(@IntegrationPortal,'') ='' OR IntegrationPortal LIKE '%' + @IntegrationPortal + '%') AND	
					(ISNULL(@StatusFilter,'') ='' OR StatusFilter LIKE '%' + @StatusFilter + '%') AND	
					(ISNULL(@DeliverByDate,'') ='' OR CAST(DeliverByDate AS Date)=CAST(@DeliverByDate AS date)) AND
					(ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber + '%') AND	
					(ISNULL(@AltPartNumber,'') ='' OR AltPartNumber LIKE '%' + @AltPartNumber + '%') AND	
					(ISNULL(@Description,'') ='' OR Description LIKE '%' + @Description + '%') AND	
					(ISNULL(@Exchange,'') ='' OR Exchange LIKE '%' + @Exchange + '%') AND	
					(ISNULL(@Qty, 0) = 0 OR CAST(Qty as VARCHAR(10)) = @Qty) AND
					(ISNULL(@RequestedQty, 0) = 0 OR CAST(RequestedQty as VARCHAR(10)) = @RequestedQty) AND
					(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND	
					(ISNULL(@IsEmail,0) ='' OR CAST(IsEmail as bit) = @IsEmail) AND	
					(ISNULL(@IsFax,0) ='' OR CAST(IsFax as bit) = @IsFax) AND		
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@VendorNames,'') ='' OR VendorNames LIKE '%' + @VendorNames + '%') AND
					(ISNULL(@VendorNamesDisplay,'') ='' OR VendorNames LIKE '%' + @VendorNamesDisplay + '%') AND
					(ISNULL(@PONumber,'') ='' OR PONumber LIKE '%' + @PONumber + '%') AND
					(ISNULL(@RFQSentDate,'') ='' OR CAST(RFQSentDate AS Date)=CAST(@RFQSentDate AS date)) AND
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND						
					(ISNULL(@VendorRFQReferenceNumber,'') ='' OR VendorRFQReferenceNumber LIKE '%' + @VendorRFQReferenceNumber + '%') AND						
					(ISNULL(@VendorResponseReceived,'') ='' OR VendorResponseReceived LIKE '%' + @VendorResponseReceived + '%') AND						
					(ISNULL(@VendorRFQPurchaseOrderNumber,'') ='' OR VendorRFQPurchaseOrderNumber LIKE '%' + @VendorRFQPurchaseOrderNumber + '%') AND						
					(ISNULL(@VendorResponseDate,'') ='' OR CAST(VendorResponseDate AS Date)=CAST(@VendorResponseDate AS date)) AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)))
				   )

			SELECT @Count = COUNT(ILSRFQPartId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='RFQId')  THEN [RFQId] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RFQId')  THEN [RFQId] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PortalRFQId')  THEN PortalRFQId END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PortalRFQId')  THEN PortalRFQId END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='Name')  THEN [Name] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Name')  THEN [Name] END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='TypeName')  THEN TypeName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TypeName')  THEN TypeName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IntegrationPortal')  THEN IntegrationPortal END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IntegrationPortal')  THEN IntegrationPortal END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='StatusFilter')  THEN [StatusFilter] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StatusFilter')  THEN [StatusFilter] END DESC,

			CASE WHEN (@SortOrder=1  AND @SortColumn='Priority')  THEN [Priority] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Priority')  THEN [Priority] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='DeliverByDate')  THEN DeliverByDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DeliverByDate')  THEN DeliverByDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AltPartNumber')  THEN AltPartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AltPartNumber')  THEN AltPartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Exchange')  THEN Exchange END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Exchange')  THEN Exchange END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Qty')  THEN Qty END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Qty')  THEN Qty END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RequestedQty')  THEN RequestedQty END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RequestedQty')  THEN RequestedQty END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsEmail')  THEN IsEmail END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsEmail')  THEN IsEmail END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsFax')  THEN IsFax END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsFax')  THEN IsFax END DESC,

			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorNames')  THEN VendorNames END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorNames')  THEN VendorNames END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PONumber')  THEN PONumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PONumber')  THEN PONumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RFQSentDate')  THEN RFQSentDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RFQSentDate')  THEN RFQSentDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorRFQReferenceNumber')  THEN VendorRFQReferenceNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorRFQReferenceNumber')  THEN VendorRFQReferenceNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorResponseReceived')  THEN VendorResponseReceived END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorResponseReceived')  THEN VendorResponseReceived END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorResponseDate')  THEN VendorResponseDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorResponseDate')  THEN VendorResponseDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorRFQPurchaseOrderNumber')  THEN VendorRFQPurchaseOrderNumber END DESC
			OFFSET @RecordFrom ROWS 
   			FETCH NEXT @PageSize ROWS ONLY

	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'ThirdPartySendRFQList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@IntegrationRFQStatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@Name, '') AS varchar(100))
			  + '@Parameter12 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END