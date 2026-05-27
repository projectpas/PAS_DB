/*********************
** File:        [USP_GetAircraftInstalledPartDetails]
** Description:
** Purpose:
** Date:
**
** RETURN VALUE:
**********************
** Change History
**********************
** PR   Date         Author				Change Description
** --   ----------   -------------		--------------------------------
** 1    2026-03-27   Amit Ghediya		Created
** 2    2026-04-07   Amit Ghediya		Get ItemMasterId for tender stk (PN-15938)
** 3    2026-04-10   Amit Ghediya		Filter apply (PN-15970)
** 4    2026-04-13   Amit Ghediya		Added for Quantity,QuantityAvailable,QuantityOnHand (PN-16028)
** 5    2026-04-21   Amit Ghediya		Added for SequenceNum (PN-16146)
** 6    2026-04-22   Amit Ghediya		Added for ConditionId (PN-16149)
** 7    2026-04-23   Priyansh Patel		Added IsCustomerStock from stockline [PN-16174]
** 8    2026-04-23   Amit Ghediya		Get item data from table [PN-16162]
** 9    2026-05-04   Abhishek Jirawla	@AircraftRegistryId if nullable get all dataa [PN-16282]
** 10   2026-05-07	 Priyansh Patel		Fixed the Remaining time calculation [PN-16306]
** 11   2026-05-04   Amit Ghediya		ATA Chapter level shows “-” when no data exists [PN-16249]
** 12   2026-05-07	 Abhishek Jirawla	Adding Make Type and Model [PN-16282]
** 13   05-12-2026   Amit Ghediya       Added item InstallFlightHours,InstalledTime,InstalledCycles,. (PN-16382)
** 13   05-13-2026   Amit Ghediya       Added item PO,RO,WO Num. (PN-16415)
** 14   18-05-2026   Ayushi Patel       Return WorksheetNumber from worksheetheader table [PN-16454]
** 14   05-13-2026   Amit Ghediya       Added item PO,RO,WO Num. (PN-16415)
** 15   05-18-2026   Abhishek Jirawla   Added item PO,RO,WO Id. (PN-16464)
** 16   05-20-2026   Priyansh Patel     Fix the WorksheetNumber to return the latest [PN-16408]
** 17   05-26-2026   Priyansh Patel     Added Worksheet Header Id [PN-16537]


*********************/
CREATE    PROCEDURE [dbo].[USP_GetAircraftInstalledPartDetails]
(
    @PageNumber         INT,
    @PageSize           INT,
    @SortColumn         VARCHAR(50) = NULL,
    @SortOrder          INT,
	@GlobalFilter VARCHAR(50) = NULL,
	@SequenceNum VARCHAR(10) = NULL,
	@PartNumber VARCHAR(100) = NULL,
	@MakeType VARCHAR(50) = NULL,
	@Model VARCHAR(100) = NULL,
	@AircraftRegistryNumber VARCHAR(30) = NULL,
	@TailNum VARCHAR(50) = NULL,
	@SerialNum VARCHAR(100) = NULL,
	@PartDescription VARCHAR(100) = NULL,
	@AtaChapter VARCHAR(50) = NULL,
	@Condition VARCHAR(50) = NULL,
	@StockLineNumber VARCHAR(50) = NULL,
	@Quantity VARCHAR(50) = NULL,
	@QuantityAvailable VARCHAR(50) = NULL,
	@QuantityOnHand VARCHAR(50) = NULL,
	@SerialNumber VARCHAR(50) = NULL,
	@ControlNumber VARCHAR(50) = NULL,
	@AircraftStatus VARCHAR(100) = NULL,
	@PositionCode VARCHAR(50) = NULL,
	@DateInstalled DATETIME = NULL,
	@Serialized VARCHAR(50) = NULL,
	@LLP VARCHAR(50) = NULL,
	@IsDeleted BIT = NULL,
	@IsActive BIT = NULL,
    @AircraftRegistryId BIGINT = NULL,
    @MasterCompanyId    BIGINT,

	@PONumber VARCHAR(50) = NULL,
	@RONumber VARCHAR(50) = NULL,
	@WONumber VARCHAR(50) = NULL,
	@WorksheetNumber VARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @RecordFrom INT = (@PageNumber - 1) * @PageSize;

		DECLARE @Count Int;

        SET @SortColumn = UPPER(ISNULL(@SortColumn, 'CREATEDDATE'));

        ;WITH Result AS
        (
            SELECT
                AIPD.AircraftInstalledPartDetailsId,
				ARH.MakeType,
				ARH.AircraftModel AS Model,
				ARH.TailNum,
				ARH.SerialNum,
                AIPD.ATAChapterId,
				CONCAT_WS(' - ',
				   NULLIF(IMAM.Level1, ''),
				   NULLIF(IMAM.Level2, ''),
				   NULLIF(IMAM.Level3, '')
			   ) AS AtaChapter,
                AIPD.PartNumber,
                AIPD.PartDescription,
				AIPD.SequenceNum,
				AIPD.ItemMasterId,
				ARH.AircraftRegistryId,
				COALESCE(ARH.AircraftRegistryNumber, '') AS AircraftRegistryNumber,
				STK.Condition,
				STK.ConditionId,
				STK.StockLineNumber,
				STK.ControlNumber,
				STK.SerialNumber,
				STK.StockLineId,
				STK.QuantityAvailable,
				STK.QuantityOnHand,
				CASE WHEN STK.IsCustomerStock = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock, 
				AIPD.Quantity,
                AIPD.IsLLP,
				AIPD.IsSerialized,
                CASE WHEN AIPD.IsLLP = 1 THEN 'YES' ELSE 'NO' END AS LLP,
				CASE WHEN AIPD.IsSerialized = 1 THEN 'YES' ELSE 'NO' END AS Serialized,
				ARH.AircraftStatusId,
				AST.Name AS AircraftStatus,
                AIPD.DateInstalled,
				AIPD.PositionCodeId,
                AIPD.PositionCode,
                AIPD.[Hours],
                AIPD.[Minutes],
				AIPD.InstallFlightHours,
				AIPD.InstallFlightTime AS 'InstallFlightMinutes',
				AIPD.PartFlightHours AS 'FlightHours',
				AIPD.PartFlightMinutes AS 'FlightMinutes',
				ISNULL(AIPD.FlightHours,0) + CAST(ISNULL(AIPD.FlightMinutes,0) AS INT) / 60 AS 'RecordFlightHours',
				CAST(ISNULL(AIPD.FlightMinutes,0) AS INT) % 60 AS 'RecordFlightMinutes',
				CASE 
					WHEN ISNULL(AIPD.PartFlightHours,0) = 0 AND ISNULL(AIPD.PartFlightMinutes,0) = 0 THEN 0
					WHEN (CAST(ISNULL(AIPD.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.PartFlightMinutes,0) AS INT))
					   - (CAST(ISNULL(AIPD.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.InstallFlightTime,0) AS INT))
					   - (CAST(ISNULL(AIPD.FlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.FlightMinutes,0) AS INT)) < 0 THEN 0
					ELSE ((CAST(ISNULL(AIPD.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.PartFlightMinutes,0) AS INT))
					   - (CAST(ISNULL(AIPD.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.InstallFlightTime,0) AS INT))
					   - (CAST(ISNULL(AIPD.FlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.FlightMinutes,0) AS INT))) / 60
				END AS 'RemainingFlightHours',
				CASE 
					WHEN ISNULL(AIPD.PartFlightHours,0) = 0 AND ISNULL(AIPD.PartFlightMinutes,0) = 0 THEN 0
					WHEN (CAST(ISNULL(AIPD.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.PartFlightMinutes,0) AS INT))
					   - (CAST(ISNULL(AIPD.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.InstallFlightTime,0) AS INT))
					   - (CAST(ISNULL(AIPD.FlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.FlightMinutes,0) AS INT)) < 0 THEN 0
					ELSE ((CAST(ISNULL(AIPD.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.PartFlightMinutes,0) AS INT))
						- (CAST(ISNULL(AIPD.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.InstallFlightTime,0) AS INT))
					   - (CAST(ISNULL(AIPD.FlightHours,0) AS INT) * 60 + CAST(ISNULL(AIPD.FlightMinutes,0) AS INT))) % 60
				END AS 'RemainingFlightMinutes',
				AIPD.InstallCycles,
                AIPD.PartCycles AS 'Cycles',
				AIPD.Cycles AS 'RecordCycles',
				CASE WHEN ISNULL(AIPD.PartCycles,0) > 0 THEN  ISNULL(AIPD.PartCycles,0) - ISNULL(AIPD.InstallCycles,0) - ISNULL(AIPD.Cycles,0) ELSE  0 END AS 'RemainingCycles',
                AIPD.PartLandings AS Landings,
				CASE WHEN ISNULL(AIPD.PartLandings,0) > 0 THEN  ISNULL(AIPD.PartLandings,0) - ISNULL(AIPD.Landings,0) ELSE  0 END AS 'RemainingLandings',
                AIPD.PartEngineStarts AS EngineStarts,
				CASE WHEN ISNULL(AIPD.PartEngineStarts,0) > 0 THEN  ISNULL(AIPD.PartEngineStarts,0) - ISNULL(AIPD.EngineStarts,0) ELSE  0 END AS 'RemainingEngineStarts',
                AIPD.Memo,
                AIPD.CreatedDate,
                AIPD.UpdatedDate,
                UPPER(AIPD.CreatedBy) AS CreatedBy,
                UPPER(AIPD.UpdatedBy) AS UpdatedBy,				
				LS.LastSequence,
				POP.PurchaseOrderId AS POId,
				PO.PurchaseOrderNumber AS 'PONumber',
				ROP.RepairOrderId AS ROId,
				RO.RepairOrderNumber AS 'RONumber',				
				WSH.WorksheetNumber,
				WOP.WorkOrderId AS WOId,
				WO.WorkOrderNum AS 'WONumber',
                WSH.WorksheetHeaderId
            FROM dbo.AircraftInstalledPartDetails AS AIPD WITH (NOLOCK)
			LEFT JOIN dbo.ItemMasterAircraftMapping IMAM WITH (NOLOCK) ON AIPD.ATAChapterId = IMAM.ItemMasterAircraftMappingId
			INNER JOIN dbo.AircraftRegistryHeader ARH WITH (NOLOCK) ON ARH.AircraftRegistryId = AIPD.AircraftRegistryId
			INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON AIPD.ItemMasterId = IM.ItemMasterId
			INNER JOIN dbo.AircraftStatus AST WITH (NOLOCK) ON AST.AircraftStatusId = ARH.AircraftStatusId
			LEFT JOIN dbo.Stockline STK WITH (NOLOCK) ON STK.StockLineId = AIPD.StockLineId
			LEFT JOIN dbo.PurchaseOrderPart POP WITH (NOLOCK) ON POP.AircraftInstalledPartDetailsId = AIPD.AircraftInstalledPartDetailsId
			LEFT JOIN dbo.PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId
			LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.AircraftInstalledPartDetailsId = AIPD.AircraftInstalledPartDetailsId
			LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
			LEFT JOIN dbo.WorkOrderPartNumber WOP WITH (NOLOCK) ON WOP.AircraftInstalledPartDetailsId = AIPD.AircraftInstalledPartDetailsId
			LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
			LEFT JOIN (SELECT *, ROW_NUMBER() OVER (PARTITION BY AircraftInstalledPartDetailsId ORDER BY CreatedDate DESC) AS RN FROM dbo.WorksheetHeader WITH (NOLOCK)) WSH ON WSH.AircraftInstalledPartDetailsId = AIPD.AircraftInstalledPartDetailsId AND WSH.RN = 1
			CROSS JOIN (
					SELECT MAX(SequenceNum) AS LastSequence
					FROM dbo.AircraftInstalledPartDetails WITH (NOLOCK)
					WHERE (@AircraftRegistryId IS NULL OR @AircraftRegistryId = 0 OR AircraftRegistryId = @AircraftRegistryId)
					AND MasterCompanyId = @MasterCompanyId
			) LS
            WHERE (@AircraftRegistryId IS NULL OR @AircraftRegistryId = 0 OR AIPD.AircraftRegistryId = @AircraftRegistryId) AND AIPD.MasterCompanyId = @MasterCompanyId
        ), ResultCount AS(SELECT COUNT(AircraftInstalledPartDetailsId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((AircraftRegistryNumber LIKE '%' +@GlobalFilter+'%') OR
					(MakeType LIKE '%' +@GlobalFilter+'%') OR
					(Model LIKE '%' +@GlobalFilter+'%') OR
					(TailNum LIKE '%' +@GlobalFilter+'%') OR
					(SerialNum LIKE '%' +@GlobalFilter+'%') OR
					([PartNumber] LIKE '%' +@GlobalFilter+'%') OR
					(SequenceNum LIKE '%' +@GlobalFilter+'%') OR
					(PartNumber LIKE '%' +@GlobalFilter+'%') OR
					(PartDescription LIKE '%' +@GlobalFilter+'%') OR
					(AtaChapter LIKE '%' +@GlobalFilter+'%') OR
					(Condition LIKE '%' +@GlobalFilter+'%') OR
					(AircraftStatus LIKE '%' +@GlobalFilter+'%') OR
					(StockLineNumber LIKE '%' +@GlobalFilter+'%') OR
					(Quantity LIKE '%' +@GlobalFilter+'%') OR    
					(QuantityAvailable LIKE '%' +@GlobalFilter+'%') OR    
					(QuantityOnHand LIKE '%' +@GlobalFilter+'%') OR    
					(SerialNumber LIKE '%' +@GlobalFilter+'%') OR
					(ControlNumber LIKE '%' +@GlobalFilter+'%') OR
					(Serialized LIKE '%' +@GlobalFilter+'%') OR
					(LLP LIKE '%' +@GlobalFilter+'%') OR
					(DateInstalled like '%' + @GlobalFilter + '%') OR
					(PositionCode LIKE '%' +@GlobalFilter+'%') OR
					(PONumber LIKE '%' +@GlobalFilter+'%') OR
					(RONumber LIKE '%' +@GlobalFilter+'%') OR
					(WONumber LIKE '%' +@GlobalFilter+'%') OR
					(WorksheetNumber LIKE '%' +@GlobalFilter+'%'))) OR
					(@GlobalFilter='' AND 
					(ISNULL(@AircraftRegistryNumber,'') ='' OR [AircraftRegistryNumber] LIKE '%' + @AircraftRegistryNumber+'%') AND
					(ISNULL(@MakeType,'') ='' OR [MakeType] LIKE '%' + @MakeType+'%') AND
					(ISNULL(@Model,'') ='' OR [Model] LIKE '%' + @Model+'%') AND
					(ISNULL(@TailNum,'') ='' OR [TailNum] LIKE '%' + @TailNum+'%') AND
					(ISNULL(@SerialNum,'') ='' OR [SerialNum] LIKE '%' + @SerialNum+'%') AND
					(ISNULL(@PartNumber,'') ='' OR [PartNumber] LIKE '%' + @PartNumber+'%') AND
					(ISNULL(@SequenceNum,'') ='' OR SequenceNum LIKE '%' + @SequenceNum + '%') AND
					(ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber + '%') AND	
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@AtaChapter,'') ='' OR AtaChapter LIKE '%' + @AtaChapter + '%') AND
					(ISNULL(@Condition,'') ='' OR Condition LIKE '%' + @Condition + '%') AND
					(ISNULL(@AircraftStatus,'') ='' OR AircraftStatus LIKE '%' + @AircraftStatus + '%') AND
					(ISNULL(@StockLineNumber,'') ='' OR StockLineNumber LIKE '%' + @StockLineNumber + '%') AND
					(ISNULL(@Quantity,'') ='' OR Quantity LIKE '%' + @Quantity + '%') AND  
					(ISNULL(@QuantityAvailable,'') ='' OR QuantityAvailable LIKE '%' + @QuantityAvailable + '%') AND
					(ISNULL(@QuantityOnHand,'') ='' OR QuantityOnHand LIKE '%' + @QuantityOnHand + '%') AND
					(ISNULL(@SerialNumber,'') ='' OR SerialNumber LIKE '%' + @SerialNumber + '%') AND
					(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%') AND
					(ISNULL(@Serialized,'') ='' OR Serialized LIKE '%' + @Serialized + '%') AND
					(ISNULL(@LLP,'') ='' OR LLP LIKE '%' + @LLP + '%') AND
					(ISNULL(@DateInstalled,'') ='' OR CAST(DateInstalled AS Date) = CAST(@DateInstalled AS Date)) AND
					(ISNULL(@PositionCode,'') ='' OR PositionCode LIKE '%' + @PositionCode + '%') AND
					(ISNULL(@PONumber,'') ='' OR PONumber LIKE '%' + @PONumber + '%') AND
					(ISNULL(@RONumber,'') ='' OR RONumber LIKE '%' + @RONumber + '%') AND
					(ISNULL(@WONumber,'') ='' OR WONumber LIKE '%' + @WONumber + '%') AND
					(ISNULL(@WorksheetNumber,'') ='' OR WorksheetNumber LIKE '%' + @WorksheetNumber + '%'))
			)
   SELECT @Count = COUNT(AircraftInstalledPartDetailsId) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			
            CASE WHEN @SortOrder =  1 AND @SortColumn = 'AircraftRegistryNumber'      THEN AircraftRegistryNumber      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'AircraftRegistryNumber'      THEN AircraftRegistryNumber      END DESC,
            
			CASE WHEN @SortOrder =  1 AND @SortColumn = 'MakeType'      THEN MakeType      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'MakeType'      THEN MakeType      END DESC,
            
			CASE WHEN @SortOrder =  1 AND @SortColumn = 'Model'      THEN Model      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'Model'      THEN Model      END DESC,
            
			CASE WHEN @SortOrder =  1 AND @SortColumn = 'TailNum'      THEN TailNum      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'TailNum'      THEN TailNum      END DESC,
            
			CASE WHEN @SortOrder =  1 AND @SortColumn = 'SerialNum'      THEN SerialNum      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'SerialNum'      THEN SerialNum      END DESC,

            CASE WHEN @SortOrder =  1 AND @SortColumn = 'ATACHAPTER'      THEN AtaChapter      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'ATACHAPTER'      THEN AtaChapter      END DESC,

            CASE WHEN @SortOrder =  1 AND @SortColumn = 'LLP'         THEN LLP         END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'LLP'         THEN LLP         END DESC,

			 CASE WHEN @SortOrder =  1 AND @SortColumn = 'Serialized'         THEN Serialized         END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'Serialized'         THEN Serialized         END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'SEQUENCENUM'      THEN SequenceNum      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'SEQUENCENUM'      THEN SequenceNum      END DESC,

            CASE WHEN @SortOrder =  1 AND @SortColumn = 'PARTNUMBER'      THEN PartNumber      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'PARTNUMBER'      THEN PartNumber      END DESC,

            CASE WHEN @SortOrder =  1 AND @SortColumn = 'PARTDESCRIPTION' THEN PartDescription END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'PARTDESCRIPTION' THEN PartDescription END DESC,

            CASE WHEN @SortOrder =  1 AND @SortColumn = 'POSITIONCODE'    THEN PositionCode    END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'POSITIONCODE'    THEN PositionCode    END DESC,

            CASE WHEN @SortOrder =  1 AND @SortColumn = 'CREATEDDATE'     THEN CreatedDate     END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'CREATEDDATE'     THEN CreatedDate     END DESC,

            CASE WHEN @SortOrder =  1 AND @SortColumn = 'UPDATEDDATE'     THEN UpdatedDate     END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'UPDATEDDATE'     THEN UpdatedDate     END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'DATEINSTALLED'     THEN DATEINSTALLED     END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'DATEINSTALLED'     THEN DATEINSTALLED     END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'CONDITION'      THEN Condition      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'CONDITION'      THEN Condition      END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'AircraftStatus'      THEN AircraftStatus      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'AircraftStatus'      THEN AircraftStatus      END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'STOCKLINENUMBER'      THEN StockLineNumber      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'STOCKLINENUMBER'      THEN StockLineNumber      END DESC,

			CASE WHEN (@SortOrder=1  AND @SortColumn='QUANTITY')  THEN Quantity END ASC,        
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QUANTITY')  THEN Quantity END DESC,

			CASE WHEN (@SortOrder=1  AND @SortColumn='QUANTITYAVAILABLE')  THEN QuantityAvailable END ASC,        
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QUANTITYAVAILABLE')  THEN QuantityAvailable END DESC,

			CASE WHEN (@SortOrder=1  AND @SortColumn='QUANTITYONHAND')  THEN QuantityOnHand END ASC,        
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QUANTITYONHAND')  THEN QuantityOnHand END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'CONTROLNUMBER'      THEN ControlNumber      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'CONTROLNUMBER'      THEN ControlNumber      END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'SERIALNUMBER'      THEN SerialNumber      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'SERIALNUMBER'      THEN SerialNumber      END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'PONUMBER'      THEN PONumber      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'PONUMBER'      THEN PONumber      END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'RONUMBER'      THEN RONumber      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'RONUMBER'      THEN RONumber      END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'WONUMBER'      THEN WONumber      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'WONUMBER'      THEN WONumber      END DESC,

			CASE WHEN @SortOrder =  1 AND @SortColumn = 'WorksheetNumber'      THEN WorksheetNumber      END ASC,
            CASE WHEN @SortOrder = -1 AND @SortColumn = 'WorksheetNumber'      THEN WorksheetNumber      END DESC,

            AircraftInstalledPartDetailsId DESC
        OFFSET @RecordFrom ROWS
        FETCH NEXT @PageSize ROWS ONLY;
    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
            @AdhocComments VARCHAR(150) = 'USP_GetAircraftInstalledPartDetails',
            @ProcedureParameters VARCHAR(3000),
            @ApplicationName VARCHAR(100) = 'PAS';

        SET @ProcedureParameters =
              '@PageNumber=' + CAST(ISNULL(@PageNumber, 0) AS VARCHAR(20))
            + ', @PageSize=' + CAST(ISNULL(@PageSize, 0) AS VARCHAR(20))
            + ', @SortColumn=' + ISNULL(@SortColumn, '')
            + ', @SortOrder=' + CAST(ISNULL(@SortOrder, 0) AS VARCHAR(20))
            + ', @AircraftRegistryId=' + CAST(ISNULL(@AircraftRegistryId, 0) AS VARCHAR(20))
            + ', @MasterCompanyId=' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(20));

        EXEC spLogException
             @DatabaseName        = @DatabaseName,
             @AdhocComments       = @AdhocComments,
             @ProcedureParameters = @ProcedureParameters,
             @ApplicationName     = @ApplicationName,
             @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR
        (
            'Unexpected error occurred in the database. Please let the support team know the error number: %d',
            16,
            1,
            @ErrorLogID
        );

        RETURN 1;
    END CATCH
END;