/*************************************************************             
 ** File:   [sp_GetCustomerInvoicedatabyInvoiceId]             
 ** Author:   Subhash Saliya  
 ** Description: Get Customer Invoicedataby InvoiceId     
 ** Purpose:           
 ** Date:   18-april-2022          
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------------		--------------------------------            
    1    04/18/2022   Subhash Saliya	Created  
	2    04/18/2022   Hemant Saliya		Resolved Ambuguancey in Amount Column  
    3    19/06/2023   Ayesha Sultana    Filter on newly added column ReceiverNum and WO
	4	 10/10/2023	  Nainshi Joshi		Removed script of "MULTIPLE" hover over 
	5	 09/07/2024	  AMIT GHEDIYA		Update for uppercase response.

 -- exec sp_GetCustomerInvoicedatabyInvoiceId 92,1      
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SearchCustomerRMAData]
	@PageSize int,
	@PageNumber int,
	@SortColumn varchar(50),
	@SortOrder int,
	@GlobalFilter varchar(50) = NULL,
	@StatusID int,
	@RMANumber varchar(50),
	@OpenDate datetime = NULL,
	@RMAReason varchar(50),
	@RMAStatus varchar(50),
	@ValidDate datetime = NULL,
	@ReturnDate datetime = NULL,
	@CustomerName varchar(50),
	@PartNumber varchar(50),
	@PartDescription varchar(50),
	@ReferenceNo varchar(50),
	@Qty varchar(50),
	@UnitPrice varchar(50),
	@Amount varchar(50),
	@Requestedby varchar(50),
	@LastMSLevel varchar(50),
	@MasterCompanyId int,
	@ViewType varchar(10),
	@EmployeeId bigint = 1,
	@IsDeleted bit,
	@Memo varchar(50),
	@ModuleID varchar(500),
	@ManufacturerName varchar(50),
	@CreditMemoRef varchar(50),
	@CreditMemoDate datetime = NULL,
	@WorkOrderNum varchar(50),
	@ReceiverNum varchar(50)
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON;
  BEGIN TRY
    DECLARE @RecordFrom int;
    DECLARE @IsActive bit = 1
    DECLARE @Count int;
    SET @RecordFrom = (@PageNumber - 1) * @PageSize;

    IF (@GlobalFilter IS NULL)
    BEGIN
      SET @GlobalFilter = '';
    END

    IF @SortColumn IS NULL
    BEGIN
      SET @SortColumn = 'RMANumber'
    END
    ELSE
    BEGIN
      SET @SortColumn = UPPER(@SortColumn)
    END

    IF LOWER(@ViewType) = 'mpn'
    BEGIN
		SELECT
        COUNT(1) OVER () AS NumberOfItems,
        CRH.[RMAHeaderId] AS RMAHeaderId,
        UPPER(CRH.[RMANumber]) AS 'RMANumber',
        CRH.[CustomerId],
        UPPER(CRH.[CustomerName]) AS 'CustomerName',
        UPPER(CRH.[CustomerCode]) AS 'CustomerCode',
        CRH.[CustomerContactId],
        UPPER(CRH.[ContactInfo]) AS 'ContactInfo',
        CRH.[OpenDate],
        UPPER(CRH.[InvoiceNo]) AS 'InvoiceNo',
        CRH.[InvoiceDate],
        CRH.[RMAStatusId],
        UPPER(CRH.[RMAStatus]) AS 'RMAStatus',
        CRH.[Iswarranty],
        CRH.[ValidDate],
        UPPER(CRH.Requestedby) AS 'Requestedby',
        CRH.[ApprovedbyId],
        UPPER(CRH.[Approvedby]) AS 'Approvedby',
        CRH.[ApprovedDate],
        CRH.[ReturnDate],
        UPPER(CRH.[ReceiverNum]) AS 'ReceiverNum',
        UPPER(CRH.[WorkorderNum]) AS 'WorkorderNum',
        CRH.[WorkOrderId],
        CRH.[ManagementStructureId],
        CRH.[Memo] AS Memo,
        CRH.[MasterCompanyId],
        UPPER(CRH.[CreatedBy]) AS 'CreatedBy',
        UPPER(CRH.[UpdatedBy]) AS 'UpdatedBy',
        CRH.[CreatedDate],
        CRH.[UpdatedDate],
        CRH.[IsActive],
        CRH.[IsDeleted],
        CRD.RMADeatilsId,
        CRD.[ItemMasterId],
        UPPER(CRD.[PartNumber]) AS 'PartNumber',
        UPPER(CRD.[PartDescription]) AS 'PartDescription',
        UPPER(CRD.[AltPartNumber]) AS 'AltPartNumber',
        UPPER(CRD.[CustPartNumber]) AS 'CustPartNumber',
        UPPER(CRD.[SerialNumber]) AS 'SerialNumber',
        UPPER(CRD.[StocklineNumber]) AS 'StocklineNumber',
        UPPER(CRD.[ControlNumber]) AS 'ControlNumber',
        CRD.[ControlId],
        UPPER(CRD.[ReferenceNo]) AS 'ReferenceNo',
        CRD.[isWorkOrder],
        ISNULL(CRD.[Qty], 0) AS [Qty],
        ISNULL(CRD.[UnitPrice], 0) AS [UnitPrice],
        ISNULL(CRD.[Amount], 0) AS [Amount],
        UPPER(RMAR.Reason) AS [RMAReason],
        UPPER(MSD.LastMSLevel) AS 'LastMSLevel',
        UPPER(MSD.AllMSlevels) AS 'AllMSlevels',
        CRH.ReferenceId,
        CM.CreditMemoHeaderId,
        UPPER(CM.CreditMemoNumber) AS CreditMemoRef,
        CM.CreatedDate AS CreditMemoDate,
        UPPER(IM.ManufacturerName) AS 'ManufacturerName'
      FROM [dbo].[CustomerRMAHeader] CRH WITH (NOLOCK)
      LEFT JOIN [dbo].[CustomerRMADeatils] CRD WITH (NOLOCK)
        ON CRD.RMAHeaderId = CRH.RMAHeaderId
      LEFT JOIN [dbo].[RMAReason] RMAR WITH (NOLOCK)
        ON CRD.RMAReasonId = RMAR.RMAReasonId
      INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK)
        ON MSD.ModuleID = @ModuleID
        AND MSD.ReferenceID = CRH.RMAHeaderId
      INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK)
        ON CRH.ManagementStructureId = RMS.EntityStructureId
      INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK)
        ON EUR.RoleId = RMS.RoleId
        AND EUR.EmployeeId = @EmployeeId
      LEFT JOIN [dbo].[CreditMemo] CM WITH (NOLOCK)
        ON CM.RMAHeaderId = CRH.RMAHeaderId
      LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK)
        ON CRD.ItemMasterId = IM.ItemMasterId
      WHERE ((CRH.MasterCompanyId = @MasterCompanyId)
      AND (CRH.IsDeleted = @IsDeleted)
      AND (@StatusID = 0
      OR CRH.RMAStatusId = @StatusID))
      AND (
      (@GlobalFilter <> ''
      AND (
      (CRH.RMANumber LIKE '%' + @GlobalFilter + '%')
      OR (CRH.CustomerName LIKE '%' + @GlobalFilter + '%')
      OR (RMAStatus LIKE '%' + @GlobalFilter + '%')
      OR (CRH.Requestedby LIKE '%' + @GlobalFilter + '%')
      OR (CRH.[Memo] LIKE '%' + @GlobalFilter + '%')
      OR (CRD.PartNumber LIKE '%' + @GlobalFilter + '%')
      OR (CRD.PartDescription LIKE '%' + @GlobalFilter + '%')
      OR (CRD.ReceiverNum LIKE '%' + @GlobalFilter + '%')
      OR (CRD.WorkOrderNum LIKE '%' + @GlobalFilter + '%')
      OR (CM.CreditMemoNumber LIKE '%' + @GlobalFilter + '%')
      OR (IM.ManufacturerName LIKE '%' + @GlobalFilter + '%')
      OR (MSD.LastMSLevel LIKE '%' + @GlobalFilter + '%')
      OR (ReferenceNo LIKE '%' + @GlobalFilter + '%')
      OR (CAST(Qty AS nvarchar(10)) LIKE '%' + @GlobalFilter + '%')
      OR (CAST(UnitPrice AS nvarchar(10)) LIKE '%' + @GlobalFilter + '%')
      OR (CAST(CRD.Amount AS nvarchar(10)) LIKE '%' + @GlobalFilter + '%')
      OR (RMAReason LIKE '%' + @GlobalFilter + '%')))
      OR (@GlobalFilter = ''
      AND (ISNULL(@RMANumber, '') = ''
      OR CRH.RMANumber LIKE '%' + @RMANumber + '%')
      AND (ISNULL(@PartNumber, '') = ''
      OR CRD.PartNumber LIKE '%' + @PartNumber + '%')
      AND (ISNULL(@PartDescription, '') = ''
      OR CRD.PartDescription LIKE '%' + @PartDescription + '%')
      AND (ISNULL(@WorkOrderNum, '') = ''
      OR CRD.WorkOrderNum LIKE '%' + @WorkOrderNum + '%')
      AND (ISNULL(@ReceiverNum, '') = ''
      OR CRD.ReceiverNum LIKE '%' + @ReceiverNum + '%')
      AND (ISNULL(@ManufacturerName, '') = ''
      OR IM.ManufacturerName LIKE '%' + @ManufacturerName + '%')
      AND (ISNULL(@LastMSLevel, '') = ''
      OR MSD.LastMSLevel LIKE '%' + @LastMSLevel + '%')
      AND (ISNULL(@CustomerName, '') = ''
      OR CRH.CustomerName LIKE '%' + @CustomerName + '%')
      AND (ISNULL(@OpenDate, '') = ''
      OR CAST(OpenDate AS date) = CAST(@OpenDate AS date))
      AND (ISNULL(@ValidDate, '') = ''
      OR CAST(ValidDate AS date) = CAST(@ValidDate AS date))
      AND (ISNULL(@ReturnDate, '') = ''
      OR CAST(CRH.ReturnDate AS date) = CAST(@ReturnDate AS date))
      AND (ISNULL(@CreditMemoDate, '') = ''
      OR CAST(CM.CreatedDate AS date) = CAST(@CreditMemoDate AS date))
      AND (ISNULL(@CreditMemoRef, '') = ''
      OR CM.CreditMemoNumber LIKE '%' + @CreditMemoRef + '%')
      AND (ISNULL(@RMAStatus, '') = ''
      OR RMAStatus LIKE '%' + @RMAStatus + '%')
      AND (ISNULL(@Memo, '') = ''
      OR CRH.[Memo] LIKE '%' + @Memo + '%')
      AND (ISNULL(@ReferenceNo, '') = ''
      OR ReferenceNo LIKE '%' + @ReferenceNo + '%')
      AND (ISNULL(@Qty, '') = ''
      OR Qty LIKE '%' + @Qty + '%')
      AND (ISNULL(@UnitPrice, '') = ''
      OR UnitPrice = @UnitPrice)
      AND (ISNULL(@Amount, '') = ''
      OR CRD.Amount = @Amount)
      AND (ISNULL(@Requestedby, '') = ''
      OR CRH.Requestedby LIKE '%' + @Requestedby + '%')
      AND (ISNULL(@RMAReason, '') = ''
      OR RMAReason LIKE '%' + @RMAReason + '%')))
      ORDER BY CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'RMANumber') THEN CRH.RMANumber
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'PartNumber') THEN CRD.PartNumber
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'PartDescription') THEN CRD.PartDescription
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'ManufacturerName') THEN ManufacturerName
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'LastMSLevel') THEN LastMSLevel
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'CustomerName') THEN CRH.CustomerName
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'OpenDate') THEN OpenDate
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'ValidDate') THEN ValidDate
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'RMAStatus') THEN RMAStatus
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'Requestedby') THEN CRH.Requestedby
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'ReturnDate') THEN CRH.ReturnDate
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'Memo') THEN CRH.[Memo]
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'ReferenceNo') THEN ReferenceNo
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'Qty') THEN Qty
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'UnitPrice') THEN UnitPrice
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'Amount') THEN CRD.Amount
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'RMAReason') THEN RMAReason
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'InvoiceDate') THEN CRH.InvoiceDate
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'CreditMemoNumber') THEN CM.CreditMemoNumber
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'CreatedDate') THEN CM.CreatedDate
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'ReceiverNum') THEN CRD.ReceiverNum
      END ASC,
      CASE
        WHEN (@SortOrder = 1 AND
          @SortColumn = 'WorkOrderNum') THEN CRD.WorkOrderNum
      END ASC,

      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'RMANumber') THEN CRH.RMANumber
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'PartNumber') THEN CRD.PartNumber
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'PartDescription') THEN CRD.PartDescription
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'ManufacturerName') THEN ManufacturerName
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'LastMSLevel') THEN LastMSLevel
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'CustomerName') THEN CRH.CustomerName
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'OpenDate') THEN OpenDate
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'ValidDate') THEN ValidDate
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'RMAStatus') THEN RMAStatus
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'Requestedby') THEN CRH.Requestedby
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'ReturnDate') THEN CRH.ReturnDate
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'Memo') THEN CRH.[Memo]
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'ReferenceNo') THEN ReferenceNo
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'Qty') THEN Qty
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'UnitPrice') THEN UnitPrice
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'Amount') THEN CRD.Amount
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'RMAReason') THEN RMAReason
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'InvoiceDate') THEN CRH.InvoiceDate
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'CreditMemoNumber') THEN CM.CreditMemoNumber
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'CreatedDate') THEN CM.CreatedDate
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'ReceiverNum') THEN CRD.ReceiverNum
      END DESC,
      CASE
        WHEN (@SortOrder = -1 AND
          @SortColumn = 'WorkOrderNum') THEN CRD.WorkOrderNum
      END DESC
      OFFSET @RecordFrom ROWS
      FETCH NEXT @PageSize ROWS ONLY
    END
	ELSE
    BEGIN
      ;WITH Result
      AS (SELECT
        CRH.[RMAHeaderId] AS RMAHeaderId,
        UPPER(CRH.[RMANumber]) AS 'RMANumber',
        CRH.[CustomerId],
        UPPER(CRH.[CustomerName]) AS 'CustomerName',
        UPPER(CRH.[CustomerCode]) AS 'CustomerCode',
        UPPER(CRH.[ContactInfo]) AS 'ContactInfo',
        CRH.[OpenDate],
        UPPER(CRH.[RMAStatus]) AS 'RMAStatus',
        CRH.[ValidDate],
        UPPER(CRH.Requestedby) AS 'Requestedby',
        UPPER(CRH.[Approvedby]) AS 'Approvedby',
        CRH.[ApprovedDate],
        CRH.[ReturnDate],
        CRH.[Memo] AS Memo,
        CRD.RMADeatilsId,
        UPPER(CRD.[ReferenceNo]) AS 'ReferenceNo',
        CRD.[isWorkOrder],
        CRH.[ReferenceId],
        UPPER(MSD.[LastMSLevel]) AS 'LastMSLevel',
        UPPER(MSD.[AllMSlevels]) AS 'AllMSlevels',
        CM.[CreditMemoHeaderId],
        UPPER(CM.[CreditMemoNumber]) AS CreditMemoRef,
        CM.[CreatedDate] AS CreditMemoDate,
        CRH.[Iswarranty],
        UPPER(CRH.[ReceiverNum]) AS 'ReceiverNum',
        UPPER(CRH.[WorkorderNum]) AS 'WorkorderNum',
        CRH.[WorkOrderId]
      FROM [dbo].[CustomerRMAHeader] CRH WITH (NOLOCK)
      LEFT JOIN [dbo].[CustomerRMADeatils] CRD WITH (NOLOCK) ON CRD.RMAHeaderId = CRH.RMAHeaderId
      LEFT JOIN [dbo].[RMAReason] RMAR WITH (NOLOCK) ON CRD.RMAReasonId = RMAR.RMAReasonId
      INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = CRH.RMAHeaderId
      INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON CRH.ManagementStructureId = RMS.EntityStructureId
      INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
      LEFT JOIN [dbo].[CreditMemo] CM WITH (NOLOCK) ON CM.RMAHeaderId = CRH.RMAHeaderId
      WHERE ((CRH.MasterCompanyId = @MasterCompanyId)
      AND (CRH.IsDeleted = @IsDeleted) AND (@StatusID = 0 OR CRH.RMAStatusId = @StatusID))),
      PartCTE
      AS (SELECT CRD.RMAHeaderId,
        (CASE
          WHEN COUNT(CRD.RMAHeaderId) > 1 THEN 'Multiple'
          ELSE A.PartNumber
        END) AS 'PartNumber'
		--,A.PartNumber [PartNumberType]
      FROM CustomerRMAHeader CRH WITH (NOLOCK)
      LEFT JOIN CustomerRMADeatils CRD WITH (NOLOCK) ON CRH.RMAHeaderId = CRD.RMAHeaderId
      OUTER APPLY (SELECT
        STUFF((SELECT
          CASE
            WHEN LEN(I.partnumber) > 0 THEN ','
            ELSE ''
          END + I.partnumber
        FROM CustomerRMADeatils S WITH (NOLOCK)
        LEFT JOIN ItemMaster I WITH (NOLOCK) ON S.ItemMasterId = I.ItemMasterId
        WHERE S.RMAHeaderId = CRD.RMAHeaderId AND S.IsActive = 1 AND S.IsDeleted = 0
        FOR xml PATH ('')), 1, 1, '') PartNumber) A
      WHERE CRH.MasterCompanyId = @MasterCompanyId AND ISNULL(CRH.IsDeleted, 0) = 0
      GROUP BY CRD.RMAHeaderId, A.PartNumber),
      PartDescCTE AS (SELECT CRD.RMAHeaderId,
        (CASE
          WHEN COUNT(CRD.RMAHeaderId) > 1 THEN 'Multiple'
          ELSE A.PartDescription END) AS 'PartDescription'
		  --,A.PartDescription [PartDescriptionType]
      FROM CustomerRMAHeader CRH WITH (NOLOCK)
      LEFT JOIN CustomerRMADeatils CRD WITH (NOLOCK) ON CRH.RMAHeaderId = CRD.RMAHeaderId
      OUTER APPLY (SELECT STUFF((SELECT
			CASE WHEN LEN(I.PartDescription) > 0 THEN ','
            ELSE ''
          END + I.PartDescription
        FROM CustomerRMADeatils S WITH (NOLOCK)
        LEFT JOIN ItemMaster I WITH (NOLOCK) ON S.ItemMasterId = I.ItemMasterId
        WHERE S.RMAHeaderId = CRD.RMAHeaderId AND S.IsActive = 1 AND S.IsDeleted = 0
        FOR xml PATH ('')), 1, 1, '') PartDescription) A
      WHERE CRH.MasterCompanyId = @MasterCompanyId
      AND ISNULL(CRH.IsDeleted, 0) = 0 GROUP BY CRD.RMAHeaderId, A.PartDescription),

      ManufacturerNameCTE
      AS (SELECT CRD.RMAHeaderId,
        (CASE
          WHEN COUNT(CRD.RMAHeaderId) > 1 THEN 'Multiple'
          ELSE A.ManufacturerName
        END) AS 'ManufacturerName'
		--,A.ManufacturerName [ManufacturerNameType]
      FROM CustomerRMAHeader CRH WITH (NOLOCK)
      LEFT JOIN CustomerRMADeatils CRD WITH (NOLOCK) ON CRH.RMAHeaderId = CRD.RMAHeaderId
      OUTER APPLY (SELECT STUFF((SELECT
          CASE
            WHEN LEN(I.ManufacturerName) > 0 THEN ','
            ELSE ''
          END + I.ManufacturerName
        FROM CustomerRMADeatils S WITH (NOLOCK)
        LEFT JOIN ItemMaster I WITH (NOLOCK) ON S.ItemMasterId = I.ItemMasterId
        WHERE S.RMAHeaderId = CRD.RMAHeaderId AND S.IsActive = 1 AND S.IsDeleted = 0 
		FOR xml PATH ('')), 1, 1, '') ManufacturerName) A
      WHERE CRH.MasterCompanyId = @MasterCompanyId
      AND ISNULL(CRH.IsDeleted, 0) = 0
      GROUP BY CRD.RMAHeaderId, A.ManufacturerName),

      RMAReasonCTE AS (SELECT
        CRD.RMAHeaderId,
        (CASE
          WHEN COUNT(CRD.RMAHeaderId) > 1 THEN 'Multiple'
          ELSE A.Reason END) AS 'RMAReason'
		--  ,A.Reason [RMAReasonType]
      FROM CustomerRMAHeader CRH WITH (NOLOCK)
      LEFT JOIN CustomerRMADeatils CRD WITH (NOLOCK) ON CRH.RMAHeaderId = CRD.RMAHeaderId
      OUTER APPLY (SELECT
        STUFF((SELECT
          CASE
            WHEN LEN(I.Reason) > 0 THEN ','
            ELSE ''
          END + I.Reason
        FROM CustomerRMADeatils S WITH (NOLOCK)
        LEFT JOIN RMAReason I WITH (NOLOCK) ON S.RMAReasonId = I.RMAReasonId
        WHERE S.RMAHeaderId = CRD.RMAHeaderId AND S.IsActive = 1 AND S.IsDeleted = 0
        FOR xml PATH ('')), 1, 1, '') Reason) A
      WHERE CRH.MasterCompanyId = @MasterCompanyId
      AND ISNULL(CRH.IsDeleted, 0) = 0
      GROUP BY CRD.RMAHeaderId, A.Reason),

      RMAQTYCTE AS (SELECT CRD.RMAHeaderId,
        (CASE
          WHEN COUNT(CRD.RMAHeaderId) > 1 THEN 'Multiple' ELSE A.Qty END) AS 'Qty'
		 -- ,A.Qty [QtyType]
      FROM CustomerRMAHeader CRH WITH (NOLOCK)
      LEFT JOIN CustomerRMADeatils CRD WITH (NOLOCK) ON CRH.RMAHeaderId = CRD.RMAHeaderId
      OUTER APPLY (SELECT
        STUFF((SELECT
          CASE
            WHEN LEN(CAST(S.Qty AS nvarchar(10))) > 0 THEN ','
            ELSE ''
          END + CAST(S.Qty AS nvarchar(10))
        FROM CustomerRMADeatils S WITH (NOLOCK)
        WHERE S.RMAHeaderId = CRD.RMAHeaderId AND S.IsActive = 1 AND S.IsDeleted = 0
        FOR xml PATH ('')), 1, 1, '') Qty) A
      WHERE CRH.MasterCompanyId = @MasterCompanyId
      AND ISNULL(CRH.IsDeleted, 0) = 0
      GROUP BY CRD.RMAHeaderId, A.Qty),

      RMAUnitPriceCTE AS (SELECT CRD.RMAHeaderId,
        (CASE
          WHEN COUNT(CRD.RMAHeaderId) > 1 THEN 'Multiple'
          ELSE A.UnitPrice
        END) AS 'UnitPrice'
		-- ,A.UnitPrice [UnitPriceType]
      FROM CustomerRMAHeader CRH WITH (NOLOCK)
      LEFT JOIN CustomerRMADeatils CRD WITH (NOLOCK) ON CRH.RMAHeaderId = CRD.RMAHeaderId
      OUTER APPLY (SELECT
        STUFF((SELECT
          CASE
            WHEN LEN(CAST(S.UnitPrice AS nvarchar(10))) > 0 THEN ','
            ELSE ''
          END + CAST(S.UnitPrice AS nvarchar(10))
        FROM CustomerRMADeatils S WITH (NOLOCK)
        WHERE S.RMAHeaderId = CRD.RMAHeaderId AND S.IsActive = 1 AND S.IsDeleted = 0
        FOR xml PATH ('')), 1, 1, '') UnitPrice) A
      WHERE CRH.MasterCompanyId = @MasterCompanyId AND ISNULL(CRH.IsDeleted, 0) = 0
      GROUP BY CRD.RMAHeaderId, A.UnitPrice),

      RMAUnitAmountCTE AS (SELECT CRD.RMAHeaderId,
        (CASE
          WHEN COUNT(CRD.RMAHeaderId) > 1 THEN 'Multiple'
          ELSE A.Amount
        END) AS 'Amount'
		--,A.Amount [AmountType]
      FROM CustomerRMAHeader CRH WITH (NOLOCK)
      LEFT JOIN CustomerRMADeatils CRD WITH (NOLOCK) ON CRH.RMAHeaderId = CRD.RMAHeaderId
      OUTER APPLY (SELECT
        STUFF((SELECT
          CASE
            WHEN LEN(CAST(S.Amount AS nvarchar(10))) > 0 THEN ','
            ELSE ''
          END + CAST(S.Amount AS nvarchar(10))
        FROM CustomerRMADeatils S WITH (NOLOCK)
        WHERE S.RMAHeaderId = CRD.RMAHeaderId AND S.IsActive = 1 AND S.IsDeleted = 0
        FOR xml PATH ('')), 1, 1, '') Amount) A
      WHERE CRH.MasterCompanyId = @MasterCompanyId AND ISNULL(CRH.IsDeleted, 0) = 0
      GROUP BY CRD.RMAHeaderId, A.Amount),

      Results AS (SELECT
        M.RMAHeaderId,
        M.[RMANumber],
        M.[CustomerId],
        M.[CustomerName],
        M.[CustomerCode],
        M.[ContactInfo],
        M.[OpenDate],
        M.[RMAStatus],
        M.[ValidDate],
        M.Requestedby,
        m.[Approvedby],
        M.[ApprovedDate],
        M.[ReturnDate],
        M.Memo,
        m.[ReferenceNo],
        m.[isWorkOrder],
        PT.PartNumber [PartNumber],
        PD.PartDescription [PartDescription],
      --  PT.PartNumberType,
      --  PD.PartDescriptionType,
       UPPER(RC.RMAReason) AS 'RMAReason',
     --   RC.RMAReasonType,
        QR.Qty,
       -- QR.QtyType,
        UC.UnitPrice,
     --   UC.UnitPriceType,
        AC.Amount,
      --  AC.AmountType,
        M.LastMSLevel,
        M.AllMSlevels,
        M.ReferenceId,
        M.CreditMemoHeaderId,
        M.Iswarranty,
        M.[WorkorderNum],
        M.[ReceiverNum],
        M.[WorkOrderId],
        MF.ManufacturerName,
       -- MF.ManufacturerNameType,
        M.CreditMemoRef,
        M.CreditMemoDate
      FROM Result M
      LEFT JOIN PartCTE PT ON M.RMAHeaderId = PT.RMAHeaderId
      LEFT JOIN PartDescCTE PD ON PD.RMAHeaderId = M.RMAHeaderId
      LEFT JOIN ManufacturerNameCTE MF ON MF.RMAHeaderId = M.RMAHeaderId
      LEFT JOIN RMAReasonCTE RC ON RC.RMAHeaderId = M.RMAHeaderId
      LEFT JOIN RMAQTYCTE QR ON QR.RMAHeaderId = M.RMAHeaderId
      LEFT JOIN RMAUnitPriceCTE UC ON UC.RMAHeaderId = M.RMAHeaderId
      LEFT JOIN RMAUnitAmountCTE AC ON AC.RMAHeaderId = M.RMAHeaderId
      GROUP BY M.RMAHeaderId,
               M.[RMANumber],
               M.[CustomerId],
               M.[CustomerName],
               M.[CustomerCode],
               M.[ContactInfo],
               M.[OpenDate],
               M.[RMAStatus],
               M.[ValidDate],
               M.Requestedby,
               m.[Approvedby],
               M.[ApprovedDate],
               M.[ReturnDate],
               M.Memo,
               m.[ReferenceNo],
               m.[isWorkOrder],
               PT.PartNumber,
               PD.PartDescription,
            --   PT.PartNumberType,
            --   PD.PartDescriptionType,
               RC.RMAReason,
             --  RC.RMAReasonType,
               QR.Qty,
            --   QR.QtyType,
               UC.UnitPrice,
            --   UC.UnitPriceType,
               AC.Amount,
             --  AC.AmountType,
               M.LastMSLevel,
               M.AllMSlevels,
               M.ReferenceId,
               M.CreditMemoHeaderId,
               M.Iswarranty,
               M.[WorkorderNum],
               M.[WorkOrderId],
               M.[ReceiverNum],
               MF.ManufacturerName,
            --   MF.ManufacturerNameType,
               M.CreditMemoRef,
               M.CreditMemoDate),
      ResultCount
      AS (SELECT COUNT(RMAHeaderId) AS totalItems FROM Results)
      SELECT * INTO #TempResult
      FROM Results WHERE (
      (@GlobalFilter <> '' AND (
      (RMANumber LIKE '%' + @GlobalFilter + '%')
      OR (CustomerName LIKE '%' + @GlobalFilter + '%')
      OR (RMAStatus LIKE '%' + @GlobalFilter + '%')
      OR (Requestedby LIKE '%' + @GlobalFilter + '%')
      OR (Memo LIKE '%' + @GlobalFilter + '%')
      OR (PartNumber LIKE '%' + @GlobalFilter + '%')
      OR (PartDescription LIKE '%' + @GlobalFilter + '%')
      OR (WorkOrderNum LIKE '%' + @GlobalFilter + '%')
      OR (ReceiverNum LIKE '%' + @GlobalFilter + '%')
      OR (ManufacturerName LIKE '%' + @GlobalFilter + '%')
      OR (LastMSLevel LIKE '%' + @GlobalFilter + '%')
      OR (CreditMemoRef LIKE '%' + @GlobalFilter + '%')
      OR (ReferenceNo LIKE '%' + @GlobalFilter + '%')
      OR (CAST(Qty AS nvarchar(10)) LIKE '%' + @GlobalFilter + '%')
      OR (CAST(UnitPrice AS nvarchar(10)) LIKE '%' + @GlobalFilter + '%')
      OR (CAST(Amount AS nvarchar(10)) LIKE '%' + @GlobalFilter + '%')
      OR (RMAReason LIKE '%' + @GlobalFilter + '%')))
      OR (@GlobalFilter = ''
      AND (ISNULL(@RMANumber, '') = '' OR RMANumber LIKE '%' + @RMANumber + '%')
      AND (ISNULL(@PartNumber, '') = '' OR PartNumber LIKE '%' + @PartNumber + '%')
      AND (ISNULL(@PartDescription, '') = '' OR PartDescription LIKE '%' + @PartDescription + '%')
      AND (ISNULL(@WorkOrderNum, '') = '' OR WorkOrderNum LIKE '%' + @WorkOrderNum + '%')
      AND (ISNULL(@ReceiverNum, '') = '' OR ReceiverNum LIKE '%' + @ReceiverNum + '%')
      AND (ISNULL(@ManufacturerName, '') = '' OR ManufacturerName LIKE '%' + @ManufacturerName + '%')
      AND (ISNULL(@LastMSLevel, '') = '' OR LastMSLevel LIKE '%' + @LastMSLevel + '%')
      AND (ISNULL(@CreditMemoRef, '') = '' OR CreditMemoRef LIKE '%' + @CreditMemoRef + '%')
      AND (ISNULL(@CustomerName, '') = '' OR CustomerName LIKE '%' + @CustomerName + '%')
      AND (ISNULL(@OpenDate, '') = '' OR CAST(OpenDate AS date) = CAST(@OpenDate AS date))
      AND (ISNULL(@ValidDate, '') = '' OR CAST(ValidDate AS date) = CAST(@ValidDate AS date))
      AND (ISNULL(@ReturnDate, '') = '' OR CAST(ReturnDate AS date) = CAST(@ReturnDate AS date))
      AND (ISNULL(@CreditMemoDate, '') = '' OR CAST(CreditMemoDate AS date) = CAST(@CreditMemoDate AS date))
      AND (ISNULL(@RMAStatus, '') = '' OR RMAStatus LIKE '%' + @RMAStatus + '%')
      AND (ISNULL(@Memo, '') = '' OR Memo LIKE '%' + @Memo + '%')
      AND (ISNULL(@ReferenceNo, '') = '' OR ReferenceNo LIKE '%' + @ReferenceNo + '%')
      AND (ISNULL(@Qty, '') = '' OR Qty LIKE '%' + @Qty + '%')
      AND (ISNULL(@UnitPrice, '') = '' OR UnitPrice = @UnitPrice)
      AND (ISNULL(@Amount, '') = '' OR Amount = @Amount)
      AND (ISNULL(@Requestedby, '') = '' OR Requestedby LIKE '%' + @Requestedby + '%')
      AND (ISNULL(@RMAReason, '') = '' OR RMAReason LIKE '%' + @RMAReason + '%')))
      SELECT @Count = COUNT(RMAHeaderId) FROM #TempResult
      SELECT *, @Count AS NumberOfItems FROM #TempResult
      ORDER BY CASE WHEN (@SortOrder = 1 AND @SortColumn = 'RMANumber') THEN RMANumber END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PartNumber') THEN PartNumber END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PartDescription') THEN PartDescription END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'WorkOrderNum') THEN WorkOrderNum END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ReceiverNum') THEN ReceiverNum END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ManufacturerName') THEN ManufacturerName END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'LastMSLevel') THEN LastMSLevel END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CustomerName') THEN CustomerName END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'OpenDate') THEN OpenDate END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ValidDate') THEN ValidDate END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'RMAStatus') THEN RMAStatus END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Requestedby') THEN Requestedby END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ReturnDate') THEN ReturnDate END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Memo') THEN Memo END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'ReferenceNo') THEN ReferenceNo END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Qty') THEN Qty END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'UnitPrice') THEN UnitPrice END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'Amount') THEN Amount END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'RMAReason') THEN RMAReason END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CreditMemoRef') THEN CreditMemoRef END ASC,
      CASE WHEN (@SortOrder = 1 AND @SortColumn = 'CreditMemoDate') THEN CreditMemoDate END ASC,

	  CASE WHEN (@SortOrder = -1 AND @SortColumn = 'RMANumber') THEN RMANumber END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ManufacturerName') THEN ManufacturerName END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'LastMSLevel') THEN LastMSLevel END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PartNumber') THEN PartNumber END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PartDescription') THEN PartDescription END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'WorkOrderNum') THEN WorkOrderNum END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ReceiverNum') THEN ReceiverNum END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CustomerName') THEN CustomerName END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'OpenDate') THEN OpenDate END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ValidDate') THEN ValidDate END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'RMAStatus') THEN RMAStatus END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Requestedby') THEN Requestedby END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ReturnDate') THEN ReturnDate END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Memo') THEN Memo END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ReferenceNo') THEN ReferenceNo END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Qty') THEN Qty END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UnitPrice') THEN UnitPrice END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'Amount') THEN Amount END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'RMAReason') THEN RMAReason END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CreditMemoRef') THEN CreditMemoRef END DESC,
      CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CreditMemoDate') THEN CreditMemoDate END DESC
      OFFSET @RecordFrom ROWS FETCH NEXT @PageSize ROWS ONLY
    END
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,
            @AdhocComments varchar(150) = 'USP_SearchCustomerRMAData',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
            + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))
            + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
            + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
            + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
            + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
            + '@Parameter7 = ''' + CAST(ISNULL(@RMANumber, '') AS varchar(100))
            + '@Parameter8 = ''' + CAST(ISNULL(@OpenDate, '') AS varchar(100))
            + '@Parameter9 = ''' + CAST(ISNULL(@RMAReason, '') AS varchar(100))
            + '@Parameter10 = ''' + CAST(ISNULL(@RMAStatus, '') AS varchar(100))
            + '@Parameter11 = ''' + CAST(ISNULL(@ValidDate, '') AS varchar(100))
            + '@Parameter12 = ''' + CAST(ISNULL(@ReturnDate, '') AS varchar(100))
            + '@Parameter13 = ''' + CAST(ISNULL(@CustomerName, '') AS varchar(100))
            + '@Parameter14 = ''' + CAST(ISNULL(@PartNumber, '') AS varchar(100))
            + '@Parameter15 = ''' + CAST(ISNULL(@PartDescription, '') AS varchar(100))
            + '@Parameter16 = ''' + CAST(ISNULL(@ReferenceNo, '') AS varchar(100))
            + '@Parameter17 = ''' + CAST(ISNULL(@Qty, '') AS varchar(100))
            + '@Parameter18 = ''' + CAST(ISNULL(@UnitPrice, '') AS varchar(100))
            + '@Parameter19 = ''' + CAST(ISNULL(@Amount, '') AS varchar(100))
            + '@Parameter20 = ''' + CAST(ISNULL(@Requestedby, '') AS varchar(100))
            + '@Parameter21 = ''' + CAST(ISNULL(@LastMSLevel, '') AS varchar(100))
            + '@Parameter22 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
            + '@Parameter23 = ''' + CAST(ISNULL(@ViewType, '') AS varchar(100))
            + '@Parameter24 = ''' + CAST(ISNULL(@EmployeeId, '') AS varchar(100))
            + '@Parameter25 = ''' + CAST(ISNULL(@IsDeleted, '') AS varchar(100))
            + '@Parameter26 = ''' + CAST(ISNULL(@Memo, '') AS varchar(100))
            + '@Parameter27 = ''' + CAST(ISNULL(@WorkOrderNum, '') AS varchar(100))
            + '@Parameter28 = ''' + CAST(ISNULL(@ReceiverNum, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END