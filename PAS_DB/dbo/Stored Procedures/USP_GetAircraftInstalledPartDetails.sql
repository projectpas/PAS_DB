/*******
** File:        [USP_GetAircraftInstalledPartDetails]
** Description:
** Purpose:
** Date:
**
** RETURN VALUE:
********
** Change History
********
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
** 13   2026-05-12   Amit Ghediya       Added item InstallFlightHours,InstalledTime,InstalledCycles,. (PN-16382)
** 13   2026-05-13   Amit Ghediya       Added item PO,RO,WO Num. (PN-16415)
** 14   2026-05-18   Ayushi Patel       Return WorksheetNumber from worksheetheader table [PN-16454]
** 14   2026-05-13   Amit Ghediya       Added item PO,RO,WO Num. (PN-16415)
** 15   2026-05-18   Abhishek Jirawla   Added item PO,RO,WO Id. (PN-16464)
** 16   2026-05-20   Priyansh Patel     Fix the WorksheetNumber to return the latest [PN-16408]
** 17   2026-05-26   Priyansh Patel     Added Worksheet Header Id [PN-16537]
** 18   2026-06-03   Amit Ghediya       Update for get latest wo created from ACIC [PN-16699]
** 19   30/06/2026	 Amit Ghediya	    Update for Engine data [PN-17075]
** 20   07/07/2026	  Kishor Makwana	[PN-17162] Updated for Get ServiceLifeUnitMonthsOrDays, ServiceLifeLimit
** 21   10/07/2026	  Amit Ghediya		Update condition

   21   01/July/2026	RAJESH GAMI		[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
   22   09/July/2026	RAJESH GAMI		[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
   24  23/July/2026	RAJESH GAMI	[PN-17350] - Removed 3 leftover IsNonStock=0 exclusion filters.
   23	17/07/2026	  Kishor Makwana	[PN-17335] Migration Change. Added Column LastInspectionDate, timeDayMonth and remainingTimeDayMonth
   24	17/07/2026	  Amit Ghediya		Update to get with direcly from part IsFromAircraft
   25	18/07/2026	  Amit Ghediya		Return IsFromAircraft as its own output column (was only used
                                        internally for the CASE branching above) so the UI can tell, per
                                        row, whether it's an aircraft- or engine-installed component.
*******/
CREATE       PROCEDURE [dbo].[USP_GetAircraftInstalledPartDetails]
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
	@WorksheetNumber VARCHAR(50) = NULL,
	@IsFromAircraft  BIT = NULL
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
				ISNULL(AIPD.IsFromAircraft,0) AS IsFromAircraft,
				CASE WHEN ISNULL(AIPD.IsFromAircraft,0) = 1 THEN ARH.MakeType ELSE ERH.MakeType END AS MakeType,
				CASE WHEN ISNULL(AIPD.IsFromAircraft,0) = 1 THEN ARH.AircraftModel ELSE ERH.EngineModel END AS Model,
				CASE WHEN ISNULL(AIPD.IsFromAircraft,0) = 1 THEN ARH.TailNum ELSE ERH.EngineName END AS TailNum,
				CASE WHEN ISNULL(AIPD.IsFromAircraft,0) = 1 THEN ARH.SerialNum ELSE ERH.SerialNum END AS SerialNum,
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
				CASE WHEN ISNULL(AIPD.IsFromAircraft,0) = 1 THEN ARH.AircraftRegistryId ELSE ERH.EngineRegistryId END AS AircraftRegistryId,
				ERH.EngineRegistryId,
				CASE WHEN ISNULL(AIPD.IsFromAircraft,0) = 1 THEN ARH.AircraftRegistryNumber ELSE ERH.EngineRegistryNumber END AS AircraftRegistryNumber,
				STK.Condition,
				STK.ConditionId,
				STK.StockLineNumber,
				STK.ControlNumber,
				STK.SerialNumber,
				STK.StockLineId,
				CSTK.StockLineId AS ReStockLineId,
				STK.QuantityAvailable,
				STK.QuantityOnHand,
				CASE WHEN STK.IsCustomerStock = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock, 
				CASE WHEN CSTK.IsCustomerStock = 1 THEN 'Yes' ELSE 'No' END AS IsReCustomerStock, 
				AIPD.Quantity,
                AIPD.IsLLP,
				AIPD.IsSerialized,
                CASE WHEN AIPD.IsLLP = 1 THEN 'YES' ELSE 'NO' END AS LLP,
				CASE WHEN AIPD.IsSerialized = 1 THEN 'YES' ELSE 'NO' END AS Serialized,
				ISNULL(ARH.AircraftStatusId, ERH.EngineStatusId) AS AircraftStatusId,
				CASE WHEN ISNULL(AIPD.IsFromAircraft,0) = 1 THEN AST.Name ELSE ERH.EngineStatus END AS AircraftStatus,
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
                WSH.WorksheetHeaderId,
				AIPD.ServiceLifeUnitMonthsOrDays,
				AIPD.ServiceLifeLimit,
				AIPD.LastInspectionDate,
				CASE WHEN ServiceLifeUnitMonthsOrDays = 1 THEN CAST(ServiceLifeLimit AS VARCHAR(20)) + ' Mths'
				WHEN ServiceLifeUnitMonthsOrDays = 2 THEN CAST(ServiceLifeLimit AS VARCHAR(20)) + ' Days'
				ELSE '' END AS timeDayMonth,
				CASE WHEN AIPD.ServiceLifeUnitMonthsOrDays = 1 THEN
				CAST(DATEDIFF(DAY,CAST(GETUTCDATE() AS DATE),DATEADD(MONTH, AIPD.ServiceLifeLimit, AIPD.LastInspectionDate)) AS VARCHAR(20)) + ' Days'
				WHEN AIPD.ServiceLifeUnitMonthsOrDays = 2 THEN CAST(DATEDIFF(DAY,CAST(GETUTCDATE() AS DATE),DATEADD(DAY, AIPD.ServiceLifeLimit, AIPD.LastInspectionDate)) AS VARCHAR(20)) + ' Days'
				ELSE '' END AS remainingTimeDayMonth
            FROM dbo.AircraftInstalledPartDetails AS AIPD WITH (NOLOCK)
			LEFT JOIN dbo.ItemMasterAircraftMapping IMAM WITH (NOLOCK) ON AIPD.ATAChapterId = IMAM.ItemMasterAircraftMappingId
			LEFT JOIN dbo.AircraftRegistryHeader ARH WITH (NOLOCK) ON ARH.AircraftRegistryId = AIPD.AircraftRegistryId AND ARH.MasterCompanyId = @MasterCompanyId  AND ISNULL(AIPD.IsFromAircraft,0) = 1
			LEFT JOIN dbo.EngineRegistryHeader ERH WITH (NOLOCK) ON ERH.EngineRegistryId = AIPD.EngineRegistryId AND ERH.MasterCompanyId = @MasterCompanyId  AND ISNULL(AIPD.IsFromAircraft,0) = 0
			INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON AIPD.ItemMasterId = IM.ItemMasterId
			LEFT JOIN dbo.AircraftStatus AST WITH (NOLOCK) ON AST.AircraftStatusId = ARH.AircraftStatusId
			LEFT JOIN dbo.Stockline STK WITH (NOLOCK) ON STK.StockLineId = AIPD.StockLineId
			LEFT JOIN [dbo].[Stockline] CSTK WITH (NOLOCK) ON CSTK.[StockLineId] = (CASE WHEN ISNULL(AIPD.IsFromAircraft,0) = 1 THEN ARH.[StockLineId] ELSE  ERH.[StockLineId] END)
			LEFT JOIN dbo.PurchaseOrderPart POP WITH (NOLOCK) ON POP.AircraftInstalledPartDetailsId = AIPD.AircraftInstalledPartDetailsId
			LEFT JOIN dbo.PurchaseOrder PO WITH (NOLOCK) ON PO.PurchaseOrderId = POP.PurchaseOrderId
			LEFT JOIN dbo.RepairOrderPart ROP WITH (NOLOCK) ON ROP.AircraftInstalledPartDetailsId = AIPD.AircraftInstalledPartDetailsId
			LEFT JOIN dbo.RepairOrder RO WITH (NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
			LEFT JOIN (SELECT *, ROW_NUMBER() OVER (PARTITION BY AircraftInstalledPartDetailsId ORDER BY CreatedDate DESC) AS RN FROM dbo.WorksheetHeader WITH (NOLOCK)) WSH ON WSH.AircraftInstalledPartDetailsId = AIPD.AircraftInstalledPartDetailsId AND WSH.RN = 1
			CROSS JOIN (
					SELECT MAX(SequenceNum) AS LastSequence
					FROM dbo.AircraftInstalledPartDetails WITH (NOLOCK)
					WHERE 
					--	IsFromAircraft = ISNULL(@IsFromAircraft, 1)
					--	AND ( @AircraftRegistryId IS NULL OR @AircraftRegistryId = 0
					--		  OR (ISNULL(@IsFromAircraft,0) = 1 AND AircraftRegistryId = @AircraftRegistryId)
					--		  OR (ISNULL(@IsFromAircraft,0) = 0 AND EngineRegistryId   = @AircraftRegistryId)
					--		 )
					----(@AircraftRegistryId IS NULL OR @AircraftRegistryId = 0 OR AircraftRegistryId = @AircraftRegistryId)
					--AND MasterCompanyId = @MasterCompanyId
					 MasterCompanyId = @MasterCompanyId
					  AND (
							@AircraftRegistryId IS NULL OR @AircraftRegistryId = 0
							OR ( ISNULL(@IsFromAircraft,0) = 1
								 AND (
									   ( AircraftRegistryId = @AircraftRegistryId
										 AND ISNULL(IsFromAircraft,0) = 1 )
									   OR ( ISNULL(IsFromAircraft,0) = 0
											AND EngineRegistryId IS NOT NULL
											AND EXISTS (
												 SELECT 1
												 FROM dbo.AircraftRegistryHeader ARH2 WITH (NOLOCK)
												 CROSS APPLY STRING_SPLIT(ARH2.EngineRegistryIds, ',') s
												 WHERE ARH2.AircraftRegistryId = @AircraftRegistryId
												   AND ARH2.MasterCompanyId = @MasterCompanyId
												   AND TRY_CONVERT(BIGINT, LTRIM(RTRIM(s.value))) = EngineRegistryId
											   ) )
									 )
							   )

							OR ( ISNULL(@IsFromAircraft,0) = 0
								 AND ISNULL(IsFromAircraft,0) = 0
								 AND EngineRegistryId = @AircraftRegistryId )
						  )
			) LS
			OUTER APPLY (SELECT TOP 1 WOP_inner.WorkOrderId,WOP_inner.ID AS WOPartNumberId
				FROM dbo.WorkOrderPartNumber WOP_inner WITH (NOLOCK)
				WHERE WOP_inner.AircraftInstalledPartDetailsId = AIPD.AircraftInstalledPartDetailsId
				ORDER BY WOP_inner.ID DESC 
			) AS WOP
			LEFT JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
            WHERE 
			--	AIPD.IsFromAircraft = ISNULL(@IsFromAircraft, 1)
			--			AND ( @AircraftRegistryId IS NULL OR @AircraftRegistryId = 0
			--				  OR (ISNULL(@IsFromAircraft,0) = 1 AND AIPD.AircraftRegistryId = @AircraftRegistryId)
			--				  OR (ISNULL(@IsFromAircraft,0) = 0 AND AIPD.EngineRegistryId   = @AircraftRegistryId) )
			----(@AircraftRegistryId IS NULL OR @AircraftRegistryId = 0 OR AIPD.AircraftRegistryId = @AircraftRegistryId)
			--AND AIPD.MasterCompanyId = @MasterCompanyId
			       AIPD.MasterCompanyId = @MasterCompanyId
					  AND (
							@AircraftRegistryId IS NULL OR @AircraftRegistryId = 0
							OR ( ISNULL(@IsFromAircraft,0) = 1
								 AND (
									   ( AIPD.AircraftRegistryId = @AircraftRegistryId
										 AND ISNULL(AIPD.IsFromAircraft,0) = 1 )
									   OR ( ISNULL(AIPD.IsFromAircraft,0) = 0
											AND AIPD.EngineRegistryId IS NOT NULL
											AND EXISTS (
												 SELECT 1
												 FROM dbo.AircraftRegistryHeader ARH2 WITH (NOLOCK)
												 CROSS APPLY STRING_SPLIT(ARH2.EngineRegistryIds, ',') s
												 WHERE ARH2.AircraftRegistryId = @AircraftRegistryId
												   AND ARH2.MasterCompanyId = @MasterCompanyId
												   AND TRY_CONVERT(BIGINT, LTRIM(RTRIM(s.value))) = AIPD.EngineRegistryId
											   ) )
									 )
							   )

							OR ( ISNULL(@IsFromAircraft,0) = 0
								 AND ISNULL(AIPD.IsFromAircraft,0) = 0
								 AND AIPD.EngineRegistryId = @AircraftRegistryId )
						  )
			--AIPD.MasterCompanyId = @MasterCompanyId
			--	  AND (
			--			@AircraftRegistryId IS NULL OR @AircraftRegistryId = 0

			--			-- AIRCRAFT MODE (=1): the aircraft's own program + all its engines' programs
			--			OR ( ISNULL(@IsFromAircraft,0) = 1
			--				 AND (
			--					   AIPD.AircraftRegistryId = @AircraftRegistryId
			--					   OR AIPD.EngineRegistryId IN (
			--							SELECT TRY_CONVERT(BIGINT, LTRIM(RTRIM(s.value)))
			--							FROM dbo.AircraftRegistryHeader ARH2 WITH (NOLOCK)
			--							CROSS APPLY STRING_SPLIT(ARH2.EngineRegistryIds, ',') s
			--							WHERE ARH2.AircraftRegistryId = @AircraftRegistryId
			--							  AND ARH2.MasterCompanyId = @MasterCompanyId
			--							  AND ISNULL(s.value,'') <> ''
			--						  )
			--					 )
			--			   )

			--			-- ENGINE MODE (0/NULL): only the selected engine's program
			--			OR ( ISNULL(@IsFromAircraft,0) = 0 AND AIPD.EngineRegistryId = @AircraftRegistryId )
			--		  )
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