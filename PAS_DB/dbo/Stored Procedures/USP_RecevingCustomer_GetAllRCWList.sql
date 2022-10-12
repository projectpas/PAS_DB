
/***************************************************************  
 ** File:   [USP_RecevingCustomer_GetAllRecevingCustomerWorkList]             
 ** Author:    HEMANT SALIYA
 ** Description: This stored procedure is used to get All Receiving Customer Work list data
 ** Purpose:           
 ** Date:   08/26/2022 
            
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  			Change Description              
 ** --   --------     -------			--------------------------------            
    1    08/26/2022    HEMANT SALIYA	 Created 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_RecevingCustomer_GetAllRCWList]
	@PageNumber int = NULL,
	@PageSize int = NULL,
	@SortColumn varchar(50) = NULL,
	@SortOrder int = NULL,
	@GlobalFilter varchar(500) = NULL,
	@xmlFilter xml
AS
BEGIN
  BEGIN TRY
    DECLARE @RecordFrom int;
    DECLARE @Count int;
    SET @RecordFrom = (@PageNumber - 1) * @PageSize;
    DECLARE @IsActive bit;
    DECLARE @MasterCompanyId bigint = NULL
	DECLARE @CustomerName varchar(100) = NULL
    DECLARE @PartNumber varchar(100) = NULL
    DECLARE @PartDescription varchar(100) = NULL
	DECLARE @SerialNumber varchar(100) = NULL
    DECLARE @StockLineNumber varchar(100) = NULL
    DECLARE @ControlNumber varchar(100) = NULL
    DECLARE @ControlIdNumber varchar(100) = NULL
	DECLARE @WorkOrderNumber varchar(100) = NULL
	DECLARE @RepairOrderNumber varchar(100) = NULL
    DECLARE @ReceivingNumber varchar(100) = NULL
    DECLARE @ReceivedDate datetime2 = NULL
	DECLARE @ReceivedBy varchar(100) = NULL
    DECLARE @StageCode varchar(100) = NULL
    DECLARE @UpdatedBy varchar(100) = NULL
	DECLARE @CreatedBy varchar(100) = NULL
    DECLARE @UpdatedDate datetime2 = NULL
	DECLARE @CreatedDate datetime2 = NULL
    DECLARE @StatusId int = NULL
    DECLARE @IsDeleted bit = NULL

    SELECT
      @StatusId =
                 CASE
                   WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'status' THEN (CASE
                       WHEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') = 'Inactive' THEN 0
                       WHEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') = 'All' THEN 2
                       ELSE 1
                     END)
                   ELSE @StatusId
                 END,
      @IsDeleted =
                  CASE
                    WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'IsDeleted' THEN CONVERT(bit, filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)'))
                    ELSE @IsDeleted
                  END,
      @MasterCompanyId =
                        CASE
                          WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'masterCompanyId' THEN CONVERT(bigint, filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)'))
                          ELSE @MasterCompanyId
                        END,
      @PartNumber =
                   CASE
                     WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(250)') = 'partNumber' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(250)')
                     ELSE @PartNumber
                   END,
      @PartDescription =
                      CASE
                        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(250)') = 'partDescription' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(250)')
                        ELSE @PartDescription
                      END,
      @SerialNumber =
                     CASE
                       WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(250)') = 'serialNumber' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(250)')
                       ELSE @SerialNumber
                     END,
      @StockLineNumber =
                        CASE
                          WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(250)') = 'stockLineNumber' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(250)')
                          ELSE @StockLineNumber
                        END,
      @ControlNumber =
                      CASE
                        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(250)') = 'controlNumber' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(250)')
                        ELSE @ControlNumber
                      END,
      @ControlIdNumber =
                        CASE
                          WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(250)') = 'controlIdNumber' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(250)')
                          ELSE @ControlIdNumber
                        END,
      @WorkOrderNumber =
                      CASE
                        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(250)') = 'WorkOrderNumber' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(250)')
                        ELSE @WorkOrderNumber
                      END,
	  @RepairOrderNumber =
                      CASE
                        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(250)') = 'repairOrderNumber' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(250)')
                        ELSE @RepairOrderNumber
                      END,
      @ReceivingNumber =
                      CASE
                        WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(250)') = 'receivingNumber' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(250)')
                        ELSE @ReceivingNumber
                      END,
	  @ReceivedDate =
                     CASE
                       WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'receivedDate' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')
                       ELSE @ReceivedDate
                     END,
	 @ReceivedBy =
                       CASE
                         WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(250)') = 'receivedBy' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(250)')
                         ELSE @ReceivedBy
                       END,
      @StageCode =
                       CASE
                         WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(250)') = 'stageCode' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(250)')
                         ELSE @StageCode
                       END,
      @UpdatedBy =
                  CASE
                    WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(250)') = 'updatedBy' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(250)')
                    ELSE @UpdatedBy
                  END,
      @UpdatedDate =
                    CASE
                      WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'updatedDate' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')
                      ELSE @UpdatedDate
                    END,
	  @CreatedBy =
                  CASE
                    WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(250)') = 'createdBy' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(250)')
                    ELSE @CreatedBy
                  END,
      @CreatedDate =
                    CASE
                      WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'createdDate' THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')
                      ELSE @CreatedDate
                    END
    FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE (filterby)

    IF @SortColumn IS NULL
    BEGIN
      SET @SortColumn = UPPER('CreatedDate')
      SET @SortOrder = -1
    END
    ELSE
    BEGIN
      SET @SortColumn = UPPER(@SortColumn)
    END
    IF @IsDeleted IS NULL
    BEGIN
      SET @IsDeleted = 0
    END
    IF (@StatusId = 0)
    BEGIN
      SET @IsActive = 0;
    END
    ELSE
    IF (@StatusId = 1)
    BEGIN
      SET @IsActive = 1;
    END
    ELSE
    BEGIN
      SET @IsActive = NULL;
    END
    SET @SortColumn = LOWER(@SortColumn)

	;WITH Result AS (SELECT
			COUNT(1) OVER () AS NumberOfItems,
			RCW.ReceivingCustomerWorkId,
			RCW.ReceivingNumber,
			SL.StockLineId,
			sl.ItemMasterId,
			CustomerName,
			PartNumber,
			PNDescription AS PartDescription,
			SerialNumber,
			StockLineNumber,
			ControlNumber,
			ControlIdNumber,
			ReceiverNumber,
			RCW.ReceivedDate,
			(er.FirstName + er.LastName) ReceivedBy,
			'' AS StageCode,
			'' AS WorkOrderNumber,
			'' AS RepairOrderNumber,
			RCW.UpdatedDate,
			RCW.CreatedDate,
			(eu.FirstName + eu.LastName) UpdatedBy,
			(ec.FirstName + ec.LastName) CreatedBy,
			RCW.IsActive,
			RCW.IsDeleted,
			MSD.LastMSLevel
      FROM [DBO].ReceivingCustomerWork RCW WITH (NOLOCK)
	  INNER JOIN [DBO].Stockline SL WITH (NOLOCK) ON RCW.StocklineId = SL.StockLineId
      INNER JOIN [DBO].StocklineDetails SLD WITH (NOLOCK) ON SLD.StockLineId = SL.StockLineId
      LEFT JOIN [DBO].Employee ec WITH (NOLOCK) ON ec.EmployeeId = RCW.CreatedBy
	  LEFT JOIN [DBO].Employee eu WITH (NOLOCK) ON eu.EmployeeId = RCW.UpdatedBy
	  LEFT JOIN [DBO].Employee er WITH (NOLOCK) ON er.EmployeeId = RCW.EmployeeId
	  INNER JOIN dbo.StocklineManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ReferenceID = SL.StockLineId
      WHERE ( SL.MasterCompanyId = @MasterCompanyId
      AND (SL.IsDeleted = @IsDeleted)
      AND (@IsActive IS NULL OR SL.IsActive = @IsActive)
      AND (@GlobalFilter = '' AND (ISNULL(@PartNumber, '') = '' OR PartNumber LIKE '%' + @PartNumber + '%')
      AND (ISNULL(@PartDescription, '') = '' OR PNDescription LIKE '%' + @PartDescription + '%')
	  AND (ISNULL(@CustomerName, '') = '' OR CustomerName LIKE '%' + @CustomerName + '%')
      AND (ISNULL(@SerialNumber, '') = '' OR SerialNumber LIKE '%' + @SerialNumber + '%')
      AND (ISNULL(@StockLineNumber, '') = '' OR StockLineNumber LIKE '%' + @StockLineNumber + '%')
      AND (ISNULL(@ControlNumber, '') = '' OR ControlNumber LIKE '%' + @ControlNumber + '%')
      AND (ISNULL(@ControlIdNumber, '') = '' OR ControlIdNumber LIKE '%' + @ControlIdNumber + '%')
	  --AND (ISNULL(@WorkOrderNumber, '') = '' OR WorkOrderId LIKE '%' + @WorkOrderNumber + '%')
	  --AND (ISNULL(@RepairOrderNumber, '') = '' OR RepairOrderNumber LIKE '%' + @RepairOrderNumber + '%')
      AND (ISNULL(@ReceivingNumber, '') = '' OR ReceivingNumber LIKE '%' + @ReceivingNumber + '%')
      AND (ISNULL(@ReceivedDate, '') = '' OR CAST(RCW.ReceivedDate AS date) = CAST(@ReceivedDate AS date))
      AND (ISNULL(@ReceivedBy, '') = '' OR CAST(er.FirstName AS varchar(100)) LIKE '%' + CAST(@ReceivedBy AS varchar) + '%')
      --AND (ISNULL(@StageCode, '') = '' OR StageCode LIKE '%' + @StageCode + '%')
      AND (ISNULL(@UpdatedBy, '') = '' OR CAST(eu.FirstName AS varchar(100)) LIKE '%' + CAST(@UpdatedBy AS varchar) + '%')
	  AND (ISNULL(@CreatedBy, '') = '' OR CAST(ec.FirstName AS varchar(100)) LIKE '%' + CAST(@CreatedBy AS varchar) + '%')
      AND (ISNULL(@CreatedDate, '') = '' OR CAST(RCW.CreatedDate AS date) = CAST(@CreatedDate AS date))
      AND (ISNULL(@UpdatedDate, '') = '' OR CAST(sl.UpdatedDate AS date) = CAST(@UpdatedDate AS date)))
      OR (
      @GlobalFilter <> ''
      AND ( PartNumber LIKE '%' + @GlobalFilter + '%'
      OR PNDescription LIKE '%' + @GlobalFilter + '%'
      OR CustomerName LIKE '%' + @GlobalFilter + '%'
      OR SerialNumber LIKE '%' + @GlobalFilter + '%'
      OR StockLineNumber LIKE '%' + @GlobalFilter + '%'
      OR ControlNumber LIKE '%' + @GlobalFilter + '%'
      OR ControlIdNumber LIKE '%' + @GlobalFilter + '%'
      --OR WorkOrderNumber LIKE '%' + @GlobalFilter + '%'
      --OR RepairOrderNumber LIKE '%' + @GlobalFilter + '%'
      OR ReceivingNumber LIKE '%' + @GlobalFilter + '%'
      OR RCW.ReceivedDate LIKE '%' + @GlobalFilter + '%'
      OR CertifiedByName LIKE '%' + @GlobalFilter + '%'
	  OR ec.FirstName LIKE '%' + @GlobalFilter + '%'
	  OR eu.FirstName LIKE '%' + @GlobalFilter + '%'
      OR er.FirstName LIKE '%' + @GlobalFilter + '%'))))

      SELECT * FROM Result t

      ORDER BY CASE
        WHEN @SortOrder = 1 THEN CASE @SortColumn
            WHEN 'customerName' THEN CONVERT(varchar(100), CustomerName)
			WHEN 'partnumber' THEN PartNumber
			WHEN 'partDescription' THEN PartDescription
			WHEN 'serialnumber' THEN serialNumber
            WHEN 'stocklinenumber' THEN stockLineNumber
			WHEN 'controlidnumber' THEN controlIdNumber
            WHEN 'controlnumber' THEN controlNumber
			WHEN 'workOrderNumber' THEN WorkOrderNumber
			WHEN 'repairOrderNumber' THEN RepairOrderNumber
			WHEN 'receivingNumber' THEN ReceivingNumber
			WHEN 'receiveddate' THEN CONVERT(varchar(100), ReceivedDate)
			WHEN 'receivedBy' THEN ReceivedBy
			WHEN 'createdBy' THEN CONVERT(varchar(100), t.createdBy)
            WHEN 'createdDate' THEN CONVERT(varchar(100), t.createdDate)
			WHEN 'updatedby' THEN CONVERT(varchar(100), t.updatedBy)
            WHEN 'updateddate' THEN CONVERT(varchar(100), t.updatedDate)
            ELSE CONVERT(varchar(100), ReceivingCustomerWorkId)
          END
      END ASC, CASE
        WHEN @SortOrder = -1 THEN CASE @SortColumn
            WHEN 'customerName' THEN CONVERT(varchar(100), CustomerName)
			WHEN 'partnumber' THEN PartNumber
			WHEN 'partDescription' THEN PartDescription
			WHEN 'serialnumber' THEN serialNumber
            WHEN 'stocklinenumber' THEN stockLineNumber
			WHEN 'controlidnumber' THEN controlIdNumber
            WHEN 'controlnumber' THEN controlNumber
			WHEN 'workOrderNumber' THEN WorkOrderNumber
			WHEN 'repairOrderNumber' THEN RepairOrderNumber
			WHEN 'receivingNumber' THEN ReceivingNumber
			WHEN 'receiveddate' THEN CONVERT(varchar(100), ReceivedDate)
			WHEN 'receivedBy' THEN ReceivedBy
			WHEN 'createdBy' THEN CONVERT(varchar(100), t.createdBy)
            WHEN 'createdDate' THEN CONVERT(varchar(100), t.createdDate)
			WHEN 'updatedby' THEN CONVERT(varchar(100), t.updatedBy)
            WHEN 'updateddate' THEN CONVERT(varchar(100), t.updatedDate)
            ELSE CONVERT(varchar(100), ReceivingCustomerWorkId)
          END
      END DESC
      OFFSET @RecordFrom ROWS
      FETCH NEXT @PageSize ROWS ONLY
  END TRY
  BEGIN CATCH
    SELECT
      ERROR_MESSAGE()
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_stockline_GetAllStocklineList',
            @ProcedureParameters varchar(max) = '@PageNumber = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
            + '@PageSize = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))
            + '@SortColumn = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
            + '@SortOrder = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
            ,@ApplicationName varchar(100) = 'PAS'
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