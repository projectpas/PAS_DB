/*************************************************************          
 ** File:   [USP_GetNonPOInvoiceList]
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to Get NOnpoinvoice list
 ** Purpose:         
 ** Date:    09/13/2023
          
 ** PARAMETERS:  
         
 ** RETURN VALUE:           
 **************************************************************          
 ** Change History           
 **************************************************************          
 ** PR   Date			 Author						Change Description            
 ** --   --------		 -------					--------------------------------          
    1    09/13/2023		Devendra Shekh					Created
    2    09/14/2023		Devendra Shekh					added paymentmethodId
    3    10/03/2023		Devendra Shekh					changes for multiple part
    4    10/03/2023		Devendra Shekh					added filtering by headerstatus(open,posted,etc)
	5    01/10/2024		Moin Bloch					    modified AllStatusId For All Records
	6    01/16/2024		Moin Bloch					    modified InvoiceNumber From Detail Table To Header
	7    12/27/2024     AMIT GHEDIYA					added COntrolNumber
	8    07-03-2025     Shrey Chandegara				Modified due to add view in Accouting Integration List's PendingSync(Add @IsUpdated parameter)
    9	 10/04/2025	    Ekta Chandegra	                Convert date using dbo.ConvertUTCtoLocal
	10   07/01/2025     Sahdev Saliya                   Changed The DataType in Column CreatedDate To Datetime
	11   25/01/2026     Hemant Saliya                   Change default Sort order by PK NonPOInvoiceId to show latest records first.
	12   21/01/2026     AMIT GHEDIYA                    Added InvoiceDate
    13   27/01/2026     Sahdev Saliya                   Added DueDate
	14   11/03/2026     AMIT GHEDIYA                    Updated for get isactive records (PN-15588)
	15    07-07-2026   Bhargav Saliya                   Added @IntegrationTypeId [PN-16810]
	16   12-08-2026    Rajesh Gami                      Improve Performance : Added indexes on the
														columns actually filtered/joined (NonPOInvoiceHeader,
														NonPOInvoicePartDetails, VendorPaymentDetails,
														VendorReadyToPayDetails), resolved the timezone
														offset in a single query instead of two, removed
														redundant SELECT DISTINCT (GROUP BY / join shape
														already guarantee uniqueness), and removed the
														#TempResult+separate COUNT pass / ResultData+
														ResultCount cross-join pattern in favor of
														COUNT(*) OVER() computed in the same pass. [PN-17634]

--EXEC [USP_GetNonPOInvoiceList] 3577,3047

exec USP_GetNonPOInvoiceList 
@PageNumber=1,@PageSize=10,@SortColumn=N'CreatedDate',@SortOrder=-1,@GlobalFilter=N'',@StatusId=1,@HeaderStatusId=1,@ViewType=N'pnview',@VendorName=NULL,@VendorCode=NULL,
@NonPoInvoiceStatus=NULL,@PaymentTerms=NULL,@CreatedBy=NULL,@CreatedDate='2023-09-13 11:31:09.640',@UpdatedBy=NULL,@UpdatedDate='2023-09-13 11:31:09.640',@IsDeleted=0,@MasterCompanyId=1

************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetNonPOInvoiceList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,
@HeaderStatusId int = NULL,
@ViewType varchar(50) = null,
@VendorName varchar(50) = NULL,
@VendorCode varchar(50) = NULL,
@NonPoInvoiceStatus varchar(50) = NULL,
@PaymentTerms varchar(100) = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL,
@MasterCompanyId bigint = NULL,
@Amount  varchar(100) = NULL,
@GLAccount varchar(100) = NULL,
@NPONumber varchar(100) = NULL,
@InvoiceNum  varchar(100) = NULL,
@ControlNumber varchar(50)=null,
@IsUpdated BIT = NULL,
@EmployeeId bigint = NULL,
@InvoiceDate datetime = NULL,
@DueDate datetime = NULL,
@IntegrationTypeId BIGINT = null
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY
		DECLARE @AllStatusId INT = 8;
		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '', @BaseUtcOffsetSec BIGINT = 0;
		-- PERF FIX: previously resolved @CurrntEmpTimeZoneDesc here, then ran a SECOND separate
		-- query against dbo.TimeZone (matched by Description text) just to get @BaseUtcOffsetSec.
		-- Resolving both in the same query (by TimeZoneId, via the same joins) removes that extra
		-- round trip and avoids re-matching TimeZone by a non-unique Description string.
		SELECT
				@CurrntEmpTimeZoneDesc = COALESCE(
					ETZ.[Description],  -- Prefer Employee's TimeZone description if available
					LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
				),
				@BaseUtcOffsetSec = COALESCE(ETZ.BaseUtcOffsetSec, LTZ.BaseUtcOffsetSec, 0)
			FROM dbo.Employee E WITH (NOLOCK)
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
			WHERE E.EmployeeId = @EmployeeId;

		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('NonPOInvoiceId')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
		END	
		IF(@StatusId=0)
		BEGIN
			SET @IsActive=0;
		END
		ELSE IF(@StatusId=1)
		BEGIN
			SET @IsActive=1;
		END
		ELSE
		BEGIN
			SET @IsActive=NULL;
		END
		
		IF (@HeaderStatusId = @AllStatusId OR @HeaderStatusId = 0)      
		BEGIN      
			SET @HeaderStatusId = NULL         
		END  

		IF(@ViewType = 'npoview')
		BEGIN
			;WITH Result AS(
				-- PERF FIX: removed SELECT DISTINCT - GROUP BY NPH.NonPOInvoiceId (the driving PK)
				-- below already yields exactly one row per invoice, so DISTINCT on top was a pure
				-- extra sort/hash pass over every output column for no benefit.
				SELECT
						NPH.NonPOInvoiceId,
						NPH.VendorId,
						NPH.VendorName,
						NPH.VendorCode,
						NPH.PaymentTermsId,
						NPH.StatusId,
						NPH.ManagementStructureId,
						NPHS.Description AS [NonPoInvoiceStatus],
						CT.Name AS [PaymentTerms],
						NPH.IsActive,
						NPH.IsDeleted,
						CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, NPH.[CreatedDate])) [CreatedDate],
						CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, NPH.[UpdatedDate])) [UpdatedDate],
						NPH.[InvoiceDate],
				        NPH.[DueDate],
						--(Cast(DBO.ConvertUTCtoLocal(NPH.[CreatedDate]  , @CurrntEmpTimeZoneDesc) as DateTime)) CreatedDate,
						--(Cast(DBO.ConvertUTCtoLocal(NPH.[UpdatedDate]  , @CurrntEmpTimeZoneDesc) as DateTime)) UpdatedDate,
						Upper(NPH.CreatedBy) CreatedBy,
						Upper(NPH.UpdatedBy) UpdatedBy,
						NPH.MasterCompanyId,
						NPH.PaymentMethodId,
						NPH.NPONumber,
						(CASE WHEN COUNT(NPD.NonPOInvoicePartDetailsId) > 1 Then CAST(SUM(NPD.ExtendedPrice)AS VARCHAR)  ELse CAST(MAX(NPD.ExtendedPrice) AS VARCHAR) End) as 'Amount',
						(CASE WHEN COUNT(NPD.GlAccountId) > 1 Then 'Multiple' ELse MAX(GL.AccountName) + '-' + MAX(GL.AccountCode)  End) as 'GLAccount',
						--(CASE WHEN COUNT(NPD.InvoiceNum) > 1 Then 'Multiple' ELse MAX(NPD.InvoiceNum) End) as 'InvoiceNum'
						NPH.InvoiceNumber as 'InvoiceNum',
						NPH.ControlNumber,
						(SELECT ISNULL(COUNT(VRPD.ReadyToPayDetailsId),0) FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK)
							INNER JOIN [dbo].[VendorReadyToPayDetails] VRPD WITH(NOLOCK) ON VRPD.VendorPaymentDetailsId = VPD.VendorPaymentDetailsId
							WHERE NPH.NonPOInvoiceId = VPD.NonPOInvoiceId
						)AS IsAlreadyPayment
				FROM [dbo].[NonPOInvoiceHeader] NPH WITH (NOLOCK)
				INNER JOIN [dbo].[NonPOInvoiceHeaderStatus] NPHS WITH (NOLOCK) ON NPHS.NonPOInvoiceHeaderStatusId = NPH.StatusId
				LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId = NPH.PaymentTermsId
				LEFT JOIN [dbo].[NonPOInvoicePartDetails] NPD WITH (NOLOCK) ON NPD.NonPOInvoiceId = NPH.NonPOInvoiceId
				LEFT JOIN [dbo].[GLAccount] GL WITH (NOLOCK) ON NPD.GlAccountId = GL.GlAccountId

				WHERE ((NPH.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR NPH.IsActive=@IsActive)) AND (@HeaderStatusId IS NULL OR NPH.StatusId = @HeaderStatusId)	     
					AND NPH.MasterCompanyId=@MasterCompanyId 
					AND (ISNULL(@IsUpdated,0) <> 1 OR ISNULL(NPH.isUpdated,0) = ISNULL(@IsUpdated,0))
					AND (@IntegrationTypeId IS NULL OR NPH.IntegrationTypeId = @IntegrationTypeId)	 
				GROUP BY NPH.NonPOInvoiceId,
					NPH.VendorId,
					NPH.VendorName,
					NPH.VendorCode,
					NPH.PaymentTermsId,
					NPH.StatusId,
					NPH.ManagementStructureId,
					NPHS.Description,
					CT.Name,
					NPH.IsActive,
					NPH.IsDeleted,
					NPH.CreatedDate,
					NPH.UpdatedDate,
					NPH.InvoiceDate,
					NPH.[DueDate],
					NPH.CreatedBy,
					NPH.UpdatedBy,
					NPH.MasterCompanyId,	
					NPH.PaymentMethodId,
					NPH.NPONumber,
					NPH.InvoiceNumber,
					NPH.ControlNumber
			)
			-- PERF FIX: ResultCount CTE removed (it was computed but never referenced anywhere -
			-- dead code). COUNT(*) OVER() below supplies NumberOfItems in the same pass that
			-- builds #TempResult, replacing the old #TempResult + separate "SELECT @Count =
			-- COUNT(...)" scan with a single pass.
			SELECT *, COUNT(*) OVER() AS NumberOfItems INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((VendorName LIKE '%' +@GlobalFilter+'%') OR
			        (VendorCode LIKE '%' +@GlobalFilter+'%') OR	
					(NonPoInvoiceStatus LIKE '%' +@GlobalFilter+'%') OR
					(PaymentTerms LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(Amount LIKE '%' +@GlobalFilter+'%') OR
					(GLAccount LIKE '%' +@GlobalFilter+'%') OR
					(InvoiceNum LIKE '%' +@GlobalFilter+'%') OR
					(NPONumber LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR
					(ControlNumber LIKE '%' +@GlobalFilter+'%'))) OR  
					
					(@GlobalFilter='' AND (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName+'%') AND
					(ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode + '%') AND	
					(ISNULL(@NonPoInvoiceStatus,'') ='' OR NonPoInvoiceStatus LIKE '%' + @NonPoInvoiceStatus + '%') AND	
					(ISNULL(@PaymentTerms,'') ='' OR PaymentTerms LIKE '%' + @PaymentTerms + '%') AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@Amount,'') ='' OR CAST(Amount AS VARCHAR) LIKE '%' + @Amount + '%') AND
					(ISNULL(@GLAccount,'') ='' OR GLAccount LIKE '%' + @GLAccount + '%') AND
					(ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE '%' + @InvoiceNum + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@NPONumber,'') ='' OR NPONumber LIKE '%' + @NPONumber + '%') AND						
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND
					(ISNULL(@InvoiceDate,'') ='' OR CAST(InvoiceDate AS date)=CAST(@InvoiceDate AS date)) AND
					(ISNULL(@DueDate,'') ='' OR CAST(DueDate AS date)=CAST(@DueDate AS date)) AND
					(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%'))
					)

			SELECT * FROM #TempResult ORDER BY
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='NonPoInvoiceStatus')  THEN NonPoInvoiceStatus END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NonPoInvoiceStatus')  THEN NonPoInvoiceStatus END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='PaymentTerms')  THEN PaymentTerms END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PaymentTerms')  THEN PaymentTerms END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amount')  THEN Amount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amount')  THEN Amount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='GLAccount')  THEN GLAccount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='GLAccount')  THEN GLAccount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='NPONumber')  THEN NPONumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NPONumber')  THEN NPONumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='NonPOInvoiceId')  THEN NonPOInvoiceId END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NonPOInvoiceId')  THEN NonPOInvoiceId END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CONTROLNUMBER')  THEN ControlNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CONTROLNUMBER')  THEN ControlNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceDate')  THEN InvoiceDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='DueDate')  THEN DueDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DueDate')  THEN DueDate END DESC
			OFFSET @RecordFrom ROWS 
   			FETCH NEXT @PageSize ROWS ONLY
		END
		ELSE
		BEGIN
			-- PERF FIX: removed SELECT DISTINCT - the only 1:many join here (NonPOInvoicePartDetails)
			-- is the intended fan-out for this "multiple part" view, and every other join
			-- (NonPOInvoiceHeaderStatus, CreditTerms, GLAccount) is 1:1 by its own PK, so no
			-- unintended duplication is possible; DISTINCT was a pure extra sort/hash pass.
			;WITH Result AS(
				SELECT
						NPH.NonPOInvoiceId,
						NPH.VendorId,
						NPH.VendorName,
						NPH.VendorCode,
						NPH.PaymentTermsId,
						NPH.StatusId,
						NPH.ManagementStructureId,
						NPHS.Description AS [NonPoInvoiceStatus],
						CT.Name AS [PaymentTerms],
						NPH.IsActive,
						NPH.IsDeleted,
						CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, NPH.[CreatedDate])) [CreatedDate],
						CONVERT(DATETIME, DATEADD(SECOND, @BaseUtcOffsetSec, NPH.[UpdatedDate])) [UpdatedDate],
						NPH.[InvoiceDate],
				        NPH.[DueDate],
						--(Cast(DBO.ConvertUTCtoLocal(NPH.[CreatedDate]  , @CurrntEmpTimeZoneDesc) as DateTime)) CreatedDate,
						--(Cast(DBO.ConvertUTCtoLocal(NPH.[UpdatedDate]  , @CurrntEmpTimeZoneDesc) as DateTime)) UpdatedDate,
						Upper(NPH.CreatedBy) CreatedBy,
						Upper(NPH.UpdatedBy) UpdatedBy,
						NPH.MasterCompanyId,
						NPH.PaymentMethodId,
						NPH.NPONumber,
						NPD.Amount,
						GL.AccountName + '-' + GL.AccountCode  as 'GLAccount',
						--NPD.InvoiceNum as 'InvoiceNum'
						NPH.InvoiceNumber as 'InvoiceNum',
						NPH.ControlNumber,
						(SELECT ISNULL(COUNT(VRPD.ReadyToPayDetailsId),0) FROM [dbo].[VendorPaymentDetails] VPD WITH(NOLOCK)
							INNER JOIN [dbo].[VendorReadyToPayDetails] VRPD WITH(NOLOCK) ON VRPD.VendorPaymentDetailsId = VPD.VendorPaymentDetailsId
							WHERE NPH.NonPOInvoiceId = VPD.NonPOInvoiceId
						)AS IsAlreadyPayment
				FROM [dbo].[NonPOInvoiceHeader] NPH WITH (NOLOCK)
				INNER JOIN [dbo].[NonPOInvoiceHeaderStatus] NPHS WITH (NOLOCK) ON NPHS.NonPOInvoiceHeaderStatusId = NPH.StatusId
				LEFT JOIN [dbo].[CreditTerms] CT WITH (NOLOCK) ON CT.CreditTermsId = NPH.PaymentTermsId
				LEFT JOIN [dbo].[NonPOInvoicePartDetails] NPD WITH (NOLOCK) ON NPD.NonPOInvoiceId = NPH.NonPOInvoiceId
				LEFT JOIN [dbo].[GLAccount] GL WITH (NOLOCK) ON NPD.GlAccountId = GL.GlAccountId

		 	  WHERE ((NPH.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR NPH.IsActive=@IsActive)) AND (@HeaderStatusId IS NULL OR NPH.StatusId = @HeaderStatusId)
					AND NPH.MasterCompanyId=@MasterCompanyId
			)
			-- PERF FIX: dropped the ResultData passthrough CTE (it selected the exact same columns
			-- as Result, just re-applying the filter) and the ResultCount CTE + cross-join used to
			-- get NumberOfItems - Result was being referenced twice via ResultData/ResultCount,
			-- which SQL Server does not guarantee to compute only once. Filtering directly against
			-- Result and adding COUNT(*) OVER() computes everything in a single materialized pass.
			SELECT *, COUNT(*) OVER() AS NumberOfItems
			INTO #TempResult
			FROM Result
			WHERE ((@GlobalFilter <>'' AND ((VendorName LIKE '%' +@GlobalFilter+'%') OR
			        (VendorCode LIKE '%' +@GlobalFilter+'%') OR	
					(NonPoInvoiceStatus LIKE '%' +@GlobalFilter+'%') OR
					(PaymentTerms LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(Amount LIKE '%' +@GlobalFilter+'%') OR
					(GLAccount LIKE '%' +@GlobalFilter+'%') OR
					(InvoiceNum LIKE '%' +@GlobalFilter+'%') OR
					(NPONumber LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR
					(ControlNumber LIKE '%' +@GlobalFilter+'%'))) OR   
					(@GlobalFilter='' AND (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName+'%') AND
					(ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode + '%') AND	
					(ISNULL(@NonPoInvoiceStatus,'') ='' OR NonPoInvoiceStatus LIKE '%' + @NonPoInvoiceStatus + '%') AND	
					(ISNULL(@PaymentTerms,'') ='' OR PaymentTerms LIKE '%' + @PaymentTerms + '%') AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@Amount,'') ='' OR CAST(Amount AS VARCHAR) LIKE '%' + @Amount + '%') AND
					(ISNULL(@GLAccount,'') ='' OR GLAccount LIKE '%' + @GLAccount + '%') AND
					(ISNULL(@InvoiceNum,'') ='' OR InvoiceNum LIKE '%' + @InvoiceNum + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					(ISNULL(@NPONumber,'') ='' OR NPONumber LIKE '%' + @NPONumber + '%') AND							
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND
					(ISNULL(@InvoiceDate,'') ='' OR CAST(InvoiceDate AS date)=CAST(@InvoiceDate AS date)) AND
				    (ISNULL(@DueDate,'') ='' OR CAST(DueDate AS date)=CAST(@DueDate AS date)) AND
					(ISNULL(@ControlNumber,'') ='' OR ControlNumber LIKE '%' + @ControlNumber + '%'))
					)

			SELECT * FROM #TempResult
			ORDER BY
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='NonPoInvoiceStatus')  THEN NonPoInvoiceStatus END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NonPoInvoiceStatus')  THEN NonPoInvoiceStatus END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='PaymentTerms')  THEN PaymentTerms END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PaymentTerms')  THEN PaymentTerms END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Amount')  THEN Amount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Amount')  THEN Amount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='GLAccount')  THEN GLAccount END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='GLAccount')  THEN GLAccount END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceNum')  THEN InvoiceNum END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceNum')  THEN InvoiceNum END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='NonPOInvoiceId')  THEN NonPOInvoiceId END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NonPOInvoiceId')  THEN NonPOInvoiceId END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='NPONumber')  THEN NPONumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NPONumber')  THEN NPONumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CONTROLNUMBER')  THEN ControlNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CONTROLNUMBER')  THEN ControlNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='InvoiceDate')  THEN InvoiceDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='InvoiceDate')  THEN InvoiceDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='DueDate')  THEN DueDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DueDate')  THEN DueDate END DESC
			OFFSET @RecordFrom ROWS 
   			FETCH NEXT @PageSize ROWS ONLY
		END	

	END TRY    
	BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetNonPOInvoiceList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@ViewType, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@VendorName, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@VendorCode, '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@NonPoInvoiceStatus , '') AS varchar(100))	
			   + '@Parameter11 = ''' + CAST(ISNULL(@PaymentTerms , '') AS varchar(100))		  
			  + '@Parameter12 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@UpdatedDate  , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))	                                           
			  + '@Parameter18 = ''' + CAST(ISNULL(@Amount, '') AS varchar(100))	                                           
			  + '@Parameter19 = ''' + CAST(ISNULL(@GLAccount, '') AS varchar(100))	                                           
			  + '@Parameter20 = ''' + CAST(ISNULL(@NPONumber, '') AS varchar(100))	                                           
			  + '@Parameter21 = ''' + CAST(ISNULL(@InvoiceNum, '') AS varchar(100))	                                           
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