/*************************************************************           
 ** File:   [GetCustomerTicketList]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used GetCustomerTicketList
 ** Purpose:         
 ** Date:   07/11/2024     
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/11/2024  Ekta Chandegra     Created
    2    31/10/2025  Bhargav Saliya     Fixed Filters issues
    3    04/11/2025  Bhargav Saliya     Fixed Utc Date issues
    4    07/11/2025  Bhargav Saliya     Fixed Filters issues For Super Admin Role
    5    21/11/2025  Bhargav Saliya     get Tickettype with Filter
    6    16/12/2025  Bhargav Saliya     Fixed Status Filter
    7    19/12/2025  Bhargav Saliya     Get New Field DaysSinceOpen And Modified Status Filter into Multiselect
	8	 22/12/2025  Bhargav Saliya     Modified [DaysSinceOpen] field

exec GetCustomerTicketList @PageNumber=1,@PageSize=10,@SortColumn=NULL,@SortOrder=-1,
@GlobalFilter=N'',@TicketId=NULL,@Subject=NULL,@StatusDescription=NULL,@AssignTo=NULL,
@ReportedBy=NULL,@DepartmentDescription=NULL,@CreatedDate=NULL,@UpdatedDate=NULL,
@IsDeleted=0,@MasterCompanyId=1,@EmployeeId=NULL,@StatusId=0,@DepartmentId=0,@CompanyName=NULL
	
************************************************************************/

CREATE    PROCEDURE [dbo].[GetCustomerTicketList]
@PageNumber INT = NULL,        
@PageSize INT = NULL,        
@SortColumn VARCHAR(50)=NULL,        
@SortOrder INT = NULL,        
@GlobalFilter VARCHAR(50) = NULL,
@TicketID VARCHAR(max) = NULL,
@Subject VARCHAR(max) = NULL,
@StatusDescription VARCHAR(100) = NULL,
@AssignTo VARCHAR(100) = NULL,
@ReportedBy VARCHAR(256) = NULL,
@DepartmentDescription VARCHAR(100) = NULL,
@CreatedDate  DATETIME = NULL,
@UpdatedDate  DATETIME = NULL,
@IsDeleted BIT = NULL,
@MasterCompanyId BIGINT = NULL,
@EmployeeId BIGINT = NULL,
@StatusIds VARCHAR(MAX) = NULL,
@DepartmentId INT = NULL,
@CompanyName VARCHAR(500) = NULL,
@UserEmployeeId BIGINT = NULL,
@TicketType VARCHAR(100) = NULL,
@Priority VARCHAR(100) = NULL,
@DaysSinceOpen VARCHAR(100) = NULL
AS 
BEGIN
	SET NOCOUNT ON;  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		DECLARE @RecordFrom INT;		
		DECLARE @Count INT;
		DECLARE @IsActive BIT;
		DECLARE @StatusCloseId BIGINT;
		DECLARE @Status TABLE (StatusId BIGINT);

		SELECT @StatusCloseId = TicketStatusId FROM [dbo].[TicketStatus] WITH (NOLOCK) WHERE [Name] = 'Closed';

		INSERT INTO @Status
		SELECT value FROM STRING_SPLIT(@StatusIds, ',');

		SET @RecordFrom = (@PageNumber - 1) * @PageSize;

		IF @EmployeeId = 0
		BEGIN
			SET @EmployeeId = NULL
		END

		--IF @StatusIds = 0
		--BEGIN
		--	SET @StatusIds = NULL
		--END

		IF @DepartmentId = 0
		BEGIN
			SET @DepartmentId = NULL
		END

		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted = 0
		END

		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
		END	

		DECLARE @empROleId BIGINT = 0;
		DECLARE @IsSupertUser BIT = 0;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description]) FROM dbo.Employee E WITH (NOLOCK) 
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @UserEmployeeId; 

		

		SELECT TOP 1 @empROleId = Id FROM DBO.UserRole WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId and [Name] = 'SUPERADMIN';

		IF EXISTS(SELECT 1 FROM DBO.EmployeeUserRole WITH(NOLOCK) WHERE EmployeeId = @UserEmployeeId AND [RoleId] = @empROleId)
		BEGIN
			SET @IsSupertUser = 1
		END

		;WITH TKT_TicketDates AS (
				SELECT
					CT.CustomerTicketId,
					TS.TicketStatusId,
					CAST(DATEDIFF(DAY,CAST(DBO.ConvertUTCtoLocal(CT.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATE),CAST(DBO.ConvertUTCtoLocal(GETUTCDATE(), @CurrntEmpTimeZoneDesc) AS DATE)) AS VARCHAR(10)) AS DaysDiff
				FROM dbo.CustomerTicket CT
				JOIN dbo.TicketStatus TS ON CT.StatusId = TS.TicketStatusId
				WHERE ISNULL(CT.IsDeleted, 0) = 0 AND CT.MasterCompanyId = @MasterCompanyId
			),

		Result AS(
			SELECT DISTINCT
				CT.CustomerTicketId,
				(ISNULL(CT.TicketID,'')) AS TicketID,
				CT.Name,
				CT.FromEmail,
				CT.ToEmail,
				(ISNULL(CT.Subject,'')) AS 'Subject',
				(ISNULL(CT.EmailBody,'')) AS 'EmailBody',
				CT.ReportedBy,
				CT.CreatedBy,
				CT.UpdatedBy,
				CASE WHEN CAST(CT.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(CT.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME))END [CreatedDate],
				CASE WHEN CAST(CT.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE)THEN NULL ELSE (Cast(DBO.ConvertUTCtoLocal(CT.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME))END [UpdatedDate],
				CT.IsActive,
				CT.IsDeleted,
				CT.MasterCompanyId,
				MS.CompanyName,
				EMP.EmployeeId AS AssignToId,
				EMP.FirstName+ ' ' +EMP.LastName AS AssignTo,
				SD.DepartmentId,
				SD.Name AS 'DepartmentName',
				SD.Description AS 'DepartmentDescription',
				TS.TicketStatusId as 'StatusId',
				TS.Name AS 'StatusName',
				TS.Description AS 'StatusDescription',
				TP.PriorityId,
				TP.Description AS 'Priority',
				tt.Description as 'TicketType',
				CASE 
				WHEN itp.TicketStatusId = @StatusCloseId THEN
					CASE 
						WHEN itp.DaysDiff = 0 THEN 'CLOSED TODAY'
						WHEN itp.DaysDiff = 1 THEN 'CLOSED YESTERDAY'
						ELSE 'CLOSED ' + itp.DaysDiff + ' DAYS AGO'
					END
				ELSE
					CASE 
						WHEN itp.DaysDiff = 0 THEN 'OPENED TODAY'
						WHEN itp.DaysDiff = 1 THEN 'OPENED YESTERDAY'
						ELSE 'OPENED ' + itp.DaysDiff + ' DAYS AGO'
					END
				END AS DaysSinceOpen,
				CASE WHEN itp.TicketStatusId = @StatusCloseId THEN 0 ELSE ISNULL(CAST(itp.DaysDiff AS INT),0) END AS DaysDiff
				--'Opened ' + CAST(DATEDIFF(DAY,CAST(DBO.ConvertUTCtoLocal(CT.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATE),CAST(DBO.ConvertUTCtoLocal(GETUTCDATE(), @CurrntEmpTimeZoneDesc) AS DATE)) AS VARCHAR(10)) + ' Days Ago' AS DaysSinceOpen
			FROM [dbo].[CustomerTicket] CT WITH (NOLOCK)
			LEFT JOIN [dbo].[MasterCompany] MS WITH (NOLOCK) ON CT.MasterCompanyId = MS.MasterCompanyId
			LEFT JOIN [dbo].[SupportDepartment] SD WITH (NOLOCK) ON CT.DepartmentId = SD.DepartmentId
			LEFT JOIN [dbo].[TicketStatus] TS WITH (NOLOCK) ON CT.StatusId = TS.TicketStatusId
			LEFT JOIN [dbo].[TicketPriority] TP WITH (NOLOCK) ON CT.PriorityId = TP.PriorityId
			LEFT JOIN [dbo].[Employee] EMP WITH (NOLOCK) ON CT.AssignTo = EMP.EmployeeId
			LEFT JOIN [dbo].[Employee] EMP1 WITH (NOLOCK) ON CT.EmployeeId = EMP1.EmployeeId
			LEFT JOIN [dbo].[CustomerTicketResponse] CTR WITH (NOLOCK) ON CT.CustomerTicketId = CTR.CustomerTicketId 
			LEFT JOIN [dbo].[TicketType] tt WITH (NOLOCK) ON CT.TicketTypeId = tt.TicketTypeId
			LEFT JOIN TKT_TicketDates itp ON CT.CustomerTicketId = itp.CustomerTicketId
			WHERE 
			(((ISNULL(@IsSupertUser, 0) = 1 AND ((@EmployeeId IS NULL OR CT.EmployeeId = @EmployeeId) OR (@EmployeeId IS NULL OR CT.AssignTo = @EmployeeId)))
				or (ISNULL(@IsSupertUser, 0) = 0 and CT.MasterCompanyId = @MasterCompanyId AND ((@EmployeeId IS NULL OR CT.EmployeeId = @EmployeeId) OR (@EmployeeId IS NULL OR CT.AssignTo = @EmployeeId))))
			AND ISNULL(CT.IsDeleted,0) = @IsDeleted
			AND (@StatusIds IS NULL OR TS.TicketStatusId IN (SELECT StatusId FROM @Status))
			AND (@DepartmentId IS NULL OR SD.DepartmentId = @DepartmentId)
			)),
			ResultCount AS (SELECT COUNT(CustomerTicketId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			WHERE ((@GlobalFilter <>'' AND (
				(TicketID LIKE '%' + @GlobalFilter + '%') OR
				(Subject LIKE '%' + @GlobalFilter + '%') OR
				(CompanyName LIKE '%' + @GlobalFilter + '%') OR
				(StatusDescription LIKE '%' + @GlobalFilter + '%') OR
				(AssignTo LIKE '%' + @GlobalFilter + '%') OR
				(ReportedBy LIKE '%' + @GlobalFilter + '%') OR
				(DepartmentDescription LIKE '%' + @GlobalFilter + '%') OR
				(TicketType LIKE '%' + @GlobalFilter + '%')))
				OR
				(@GlobalFilter = '' AND (ISNULL(@TicketID,'') = '' OR  TicketID LIKE '%' + @TicketID + '%') AND
				(ISNULL(@Subject,'') = '' OR Subject LIKE '%' + @Subject + '%') AND
				(ISNULL(@CompanyName,'') = '' OR CompanyName LIKE '%' + @CompanyName + '%') AND
				(ISNULL(@StatusDescription,'') = '' OR statusDescription LIKE '%' + @StatusDescription + '%') AND
				(ISNULL(@AssignTo,'') = '' OR AssignTo LIKE '%' + @AssignTo + '%') AND
				(ISNULL(@ReportedBy,'') = '' OR ReportedBy LIKE '%' + @ReportedBy + '%') AND
				(ISNULL(@DepartmentDescription,'') = '' OR DepartmentDescription LIKE '%' + @DepartmentDescription + '%') AND
				(ISNULL(@CreatedDate,'') = '' OR CAST(CreatedDate AS DATE)=CAST(@CreatedDate AS DATE)) AND
				(ISNULL(@UpdatedDate,'') = '' OR CAST(UpdatedDate AS DATE)=CAST(@UpdatedDate AS DATE)) AND
				(ISNULL(@TicketType,'') = '' OR TicketType LIKE '%' + @TicketType + '%') AND
				(ISNULL(@Priority,'') = '' OR Priority LIKE '%' + @Priority + '%') and
				(ISNULL(@DaysSinceOpen,'') = '' OR DaysSinceOpen LIKE '%' + @DaysSinceOpen + '%'))
			)

			SELECT @Count = COUNT(CustomerTicketId) FROM #TempResult			
			SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='TicketID')  THEN TicketID END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TicketID')  THEN TicketID END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Subject')  THEN Subject END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Subject')  THEN Subject END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyName')  THEN CompanyName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName')  THEN CompanyName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='StatusDescription')  THEN StatusDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StatusDescription')  THEN StatusDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='AssignTo')  THEN AssignTo END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='AssignTo')  THEN AssignTo END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ReportedBy')  THEN ReportedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ReportedBy')  THEN ReportedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='DepartmentDescription')  THEN DepartmentDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DepartmentDescription')  THEN DepartmentDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='TicketType')  THEN TicketType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TicketType')  THEN TicketType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Priority')  THEN Priority END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Priority')  THEN Priority END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='DaysSinceOpen')  THEN DaysSinceOpen END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='DaysSinceOpen')  THEN DaysSinceOpen END DESC

			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
	END TRY
	BEGIN CATCH
	 DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetCustomerTicketList'
			,@ProcedureParameters VARCHAR(3000) =
			'@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''',   
			 @Parameter2 = ' + ISNULL(@PageSize,'') + ',    
			 @Parameter3 = ' + ISNULL(@SortColumn,'') + ',         
             @Parameter4 = ' + ISNULL(@SortOrder,'') + ',         
             @Parameter5 = ' + ISNULL(@GlobalFilter,'') + ',
             @Parameter6 = ' + ISNULL(@TicketID,'') + ',
             @Parameter7 = ' + ISNULL(@Subject,'') + ',
             @Parameter8 = ' + ISNULL(@StatusDescription,'') + ',
             @Parameter9 = ' + ISNULL(@AssignTo,'') + ',
             @Parameter10 = ' + ISNULL(@ReportedBy,'') + ',
             @Parameter11 = ' + ISNULL(@DepartmentDescription,'') + ',
             @Parameter12 = ' + ISNULL(CAST(@CreatedDate AS varchar(20)) ,'') +''',
             @Parameter13 = ' + ISNULL(CAST(@UpdatedDate AS varchar(20)) ,'') +''',
             @Parameter14 = ' + ISNULL(@IsDeleted ,'') + ',
             @Parameter15 = ' + ISNULL(@MasterCompanyId,'') + ',
             @Parameter16 = ' + ISNULL(@EmployeeId,'') + ',
             @Parameter17 = ' + ISNULL(@StatusIds,'') + ',
             @Parameter18 = ' + ISNULL(@DepartmentId,'') + ',
             @Parameter19 = ' + ISNULL(@CompanyName,'') + ','
             , @ApplicationName VARCHAR(100) = 'PAS'        
-----------------------------PLEASE DO NOT EDIT BELOW----------------------------------------        
              exec spLogException         
                       @DatabaseName           = @DatabaseName        
                     , @AdhocComments          = @AdhocComments        
                     , @ProcedureParameters = @ProcedureParameters        
                     , @ApplicationName        =  @ApplicationName        
                     , @ErrorLogID   = @ErrorLogID OUTPUT ;        
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)        
              RETURN(1); 				
	END CATCH
END