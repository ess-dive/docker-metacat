<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" encoding="UTF-8" omit-xml-declaration="yes" indent="yes" media-type="application/json"/>
    <xsl:strip-space elements="*"/>
    <xsl:variable name="APOS">'</xsl:variable>

    <!-- Grab default parameter contextURL-->
    <xsl:param name="contextURL"/>
    <xsl:param name="pid"/>
    <xsl:param name="serverName"/>
    <xsl:param name="catalogName"><![CDATA[ESS-DIVE]]></xsl:param>
    <xsl:param name="catalogId"><![CDATA[https://doi.org/10.25504/FAIRsharing.d6Pe1f]]></xsl:param>
    <xsl:param name="catalogURL"><![CDATA[https://]]><xsl:value-of select="$serverName" /></xsl:param>
    <xsl:param name="viewURL"><xsl:value-of select="$catalogURL"/><![CDATA[/view]]></xsl:param>
    <xsl:param name="url"><xsl:value-of select="$viewURL" /><![CDATA[/]]><xsl:value-of select="$pid" /></xsl:param>
    <xsl:param name="objectURL"><xsl:value-of select="$catalogURL" /><![CDATA[/catalog/d1/mn/v2/object]]></xsl:param>

    <xsl:template match="@* | node()">

        <xsl:call-template name="dataset"/>

    </xsl:template>

    <xsl:template name="dataset">
        <xsl:param name="package_id"/>
        {
        "@context": "http://schema.org/",
        "url": "<xsl:value-of select="$url"/>",
        "@type": "Dataset",
        "@id": "<xsl:value-of select="$url"/>",
                <xsl:if test="dataset/annotation[propertyURI/@label='same as']">
        "identifier": [<xsl:for-each select="dataset/annotation[propertyURI/@label='same as']">
            {
                "@type": "PropertyValue",
                "propertyID": "DOI",
                "value": "<xsl:call-template name="replace-all">
                 <xsl:with-param name="text" select="valueURI/@label"/>
                 <xsl:with-param name="replace">doi:</xsl:with-param>
                </xsl:call-template>"
            }<xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
            </xsl:for-each>
            ],
        "sameAs": [<xsl:for-each select="dataset/annotation[propertyURI/@label='same as']">
            "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="valueURI"/></xsl:call-template>"<xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
            </xsl:for-each>
            ],</xsl:if>
        <xsl:if test="dataset/annotation[propertyURI/@label='archived at']">
        "archivedAt": [<xsl:for-each select="dataset/annotation[propertyURI/@label='archived at']">
            {
                "@type": "WebPage",
                "name": "<xsl:value-of select="valueURI/@label"/>",
                "url": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="valueURI"/></xsl:call-template>"
            }<xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
            </xsl:for-each>
        ],</xsl:if>
        <xsl:if test="dataset/annotation[propertyURI/@label='has part']">
        "hasPart": [<xsl:for-each select="dataset/annotation[propertyURI/@label='has part']">
            {
                "@type": "WebPage",
                "name": "<xsl:value-of select="valueURI/@label"/>",
                "url": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="valueURI"/></xsl:call-template>"
            }<xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
            </xsl:for-each>
            ],</xsl:if>
        "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/title"/></xsl:call-template>",
        "includedInDataCatalog": { "name": "<xsl:value-of select="$catalogName"/>",
                                   "url": "<xsl:value-of select="$catalogURL"/>",
                                   "identifier": "<xsl:value-of select="$catalogId"/>"},
        "description":
        [
        <xsl:for-each select="dataset/abstract/para">
            "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="text()"/></xsl:call-template>"<xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        ],
        <xsl:if test="dataset/alternateIdentifier">
            "alternateName": [
            <xsl:for-each select="dataset/alternateIdentifier">
                "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="."/></xsl:call-template>"
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            ],
        </xsl:if>
        "creator": [
        <xsl:for-each  select="dataset/creator">{
            "@type": "Person",
            <xsl:if test="userId">
            "@id": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="userId"/></xsl:call-template>",
            </xsl:if>
            "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/givenName"/></xsl:call-template><xsl:text> </xsl:text><xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/surName"/></xsl:call-template>",
            "givenName":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/givenName"/></xsl:call-template>",
            "familyName":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/surName"/></xsl:call-template>"
            <xsl:if test="organizationName or electronicMailAddress">
                    <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:if test="organizationName">
                "affiliation":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="organizationName"/></xsl:call-template>"
                <xsl:if test="electronicMailAddress">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:if>
            <xsl:if test="electronicMailAddress">"email":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="electronicMailAddress"/></xsl:call-template>"</xsl:if>
            }
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        ],
        <xsl:if test="dataset/associatedParty[role='contributor']">
        "contributor": [
        <xsl:for-each select="dataset/associatedParty[role='contributor']">{
            "@type": "Person",
            <xsl:if test="userId">
            "@id": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="userId"/></xsl:call-template>",
            </xsl:if>
            "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/givenName"/></xsl:call-template><xsl:text> </xsl:text><xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/surName"/></xsl:call-template>",
            "givenName":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/givenName"/></xsl:call-template>",
            "familyName":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="individualName/surName"/></xsl:call-template>"
            <xsl:if test="organizationName or electronicMailAddress">
                    <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:if test="organizationName">
                "affiliation":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="organizationName"/></xsl:call-template>"
                <xsl:if test="electronicMailAddress">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:if>
            <xsl:if test="electronicMailAddress">"email":"<xsl:call-template name="transform-string"><xsl:with-param name="content" select="electronicMailAddress"/></xsl:call-template>"</xsl:if>
            }
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        ],
        </xsl:if>
        <xsl:if test="dataset/pubDate">"datePublished": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/pubDate"/></xsl:call-template>",</xsl:if>
        "keywords": [
        <xsl:for-each select="dataset/keywordSet[keywordThesaurus[contains(text(),'CATEGORICAL')] or not(keywordThesaurus)]">
            <xsl:for-each select="keyword">
                "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="."/></xsl:call-template>"
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        ]
        <xsl:if test="dataset/keywordSet[keywordThesaurus[contains(text(),'VARIABLE')]]">
        ,"variableMeasured": [
        <xsl:for-each select="dataset/keywordSet[keywordThesaurus[contains(text(),'VARIABLE')]]">
            <xsl:for-each select="keyword">
                "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="."/></xsl:call-template>"
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
            </xsl:if>
        </xsl:for-each>
        ]
        </xsl:if>
        <xsl:if test="dataset/intellectualRights/para">
            <xsl:choose>
                <xsl:when test="contains(.,'http://creativecommons.org/licenses/by/4.0/')">
                    ,"license": "http://creativecommons.org/licenses/by/4.0/"
                </xsl:when>
                <xsl:otherwise>
                    ,"license": "http://creativecommons.org/publicdomain/zero/1.0/"
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:if test="dataset/coverage/geographicCoverage">
            ,"spatialCoverage": [
            <xsl:for-each select="dataset/coverage/geographicCoverage">
                {
                "@type": "Place",
                <xsl:if test="geographicDescription">
                    "description": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="geographicDescription"/></xsl:call-template>",
                </xsl:if>
                <xsl:if test="boundingCoordinates">
                    "geo": [
                    {
                    "@type": "GeoCoordinates",
                    "name": "Northwest",
                    "latitude": <xsl:value-of select="translate(normalize-space( boundingCoordinates/northBoundingCoordinate),' +', '')"/>,
                    "longitude": <xsl:value-of select="translate(normalize-space( boundingCoordinates/westBoundingCoordinate),' +', '')"/>
                    },
                    {
                    "@type": "GeoCoordinates",
                    "name": "Southeast",
                    "latitude": <xsl:value-of select="translate(normalize-space( boundingCoordinates/southBoundingCoordinate),' +', '')"/>,
                    "longitude": <xsl:value-of select="translate(normalize-space( boundingCoordinates/eastBoundingCoordinate),' +', '')"/>
                    }
                    ]
                </xsl:if>
                }<xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            ]
        </xsl:if>
        <xsl:if test="dataset/project/funding">
            ,"award": [
            <xsl:for-each select="dataset/project/funding/para">
                "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="substring-after(.,'DOE:')"/></xsl:call-template>"
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            ]
        </xsl:if>
        <xsl:if test="dataset/associatedParty[role[text()='fundingOrganization']]">
            ,"funder": [
            <xsl:for-each select="dataset/associatedParty[role[text()='fundingOrganization']]">
                {
                "@type": "Organization",
                <xsl:if test="userId">
                    "@id": "<xsl:value-of select="normalize-space(userId)"/>",
                </xsl:if>
                "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="organizationName"/></xsl:call-template>"
                }
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            ]
        </xsl:if>
        <xsl:if test="dataset/coverage/temporalCoverage/rangeOfDates">
            ,"temporalCoverage":"<xsl:value-of select="dataset/coverage/temporalCoverage/rangeOfDates[1]/beginDate/calendarDate"/><xsl:choose>
                <xsl:when test="dataset/coverage/temporalCoverage/rangeOfDates[1]/endDate/calendarDate and dataset/coverage/temporalCoverage/rangeOfDates[1]/beginDate/calendarDate">/<xsl:value-of select="dataset/coverage/temporalCoverage/rangeOfDates[1]/endDate/calendarDate"/></xsl:when>
                <xsl:otherwise>..</xsl:otherwise></xsl:choose>"</xsl:if><xsl:if test="dataset/contact[position() = 1]">
            ,"editor": {
            "@type": "Person",
            <xsl:if test="dataset/contact[position() = 1]/userId">"@id": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/userId"/></xsl:call-template>",
            </xsl:if>
            "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/individualName/givenName"/></xsl:call-template><xsl:text> </xsl:text><xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/individualName/surName"/></xsl:call-template>",
            "givenName": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/individualName/givenName"/></xsl:call-template>",
            "familyName": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/individualName/surName"/></xsl:call-template>"<xsl:if test="dataset/contact[position() = 1]/organizationName or dataset/contact[position() = 1]/electronicMailAddress ">
                <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:if test="dataset/contact[position() = 1]/organizationName">
            "affiliation": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/organizationName"/></xsl:call-template>"<xsl:if test="dataset/contact[position() = 1]/electronicMailAddress">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:if><xsl:if test="dataset/contact[position() = 1]/electronicMailAddress">
            "email": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/contact[position() = 1]/electronicMailAddress"/></xsl:call-template>"
            </xsl:if>}
        </xsl:if>
        <xsl:if test="dataset/additionalInfo/section[title[text()='Related References']]/para">
            ,"citation": [
            <xsl:for-each select="dataset/additionalInfo/section[title[text()='Related References']]/para">
                "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="."/></xsl:call-template>"
                <xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>

            ]
        </xsl:if>
        <xsl:if test="dataset/project">
            ,"provider": {
            "@type": "Organization",
            "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/title"/></xsl:call-template>",
            "member":
            {
            "@type": "Person",<xsl:if test="translate(translate(normalize-space( dataset/project/personnel/userId),' &#x9;&#xa;&#xd;', ' '), '&quot;', $APOS)">
            "@id": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/userId"/></xsl:call-template>",</xsl:if>
            "name": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/individualName/givenName"/></xsl:call-template><xsl:text> </xsl:text><xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/individualName/surName"/></xsl:call-template>",
            "givenName": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/individualName/givenName"/></xsl:call-template>",
            "familyName": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/individualName/surName"/></xsl:call-template>",
            "jobTitle": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/role"/></xsl:call-template>"<xsl:if test="dataset/project/personnel/electronicMailAddress or dataset/project/personnel/organizationName">
                <xsl:text>,</xsl:text>
            </xsl:if><xsl:if test="dataset/project/personnel/organizationName">
            "affiliation": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/organizationName"/></xsl:call-template>"<xsl:if test="dataset/project/personnel/electronicMailAddress">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:if><xsl:if test="dataset/project/personnel/electronicMailAddress">
            "email": "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="dataset/project/personnel/electronicMailAddress"/></xsl:call-template>"
            </xsl:if>}
            }
        </xsl:if>
        <xsl:if test="dataset/methods">
            ,"measurementTechnique": [
            <xsl:for-each select="dataset/methods/*/*/para">
                "<xsl:call-template name="transform-string"><xsl:with-param name="content" select="text()"/></xsl:call-template>"<xsl:if test="position() != last()">
                    <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            ]
        </xsl:if>
        <xsl:if test="dataset/otherEntity">
            ,"distribution": [
            <xsl:for-each select="dataset/otherEntity">
                {"@type":"DataDownload",
                "name":"<xsl:value-of select="entityName"/>",
                "encodingFormat":"<xsl:value-of select="entityType"/>"<xsl:if test="@id">,
                "identifier": "<xsl:value-of select="@id"/>",
                "contentUrl": "<xsl:value-of select="$objectURL" /><![CDATA[/]]><xsl:value-of select="@id"/>"
                </xsl:if>}
                <xsl:if test="position() != last()">
                <xsl:text>,</xsl:text>
                </xsl:if>
            </xsl:for-each>
            ]
        </xsl:if>
        }
    </xsl:template>

    <!-- transform-string
    Transforms the string for valid JSON

    This template does the following
    + normalizes spaces with normalize-space
    + translates the invalid characters to spaces
    + translates $quot; to $APOS

    content - the string to transform
    -->
    <xsl:template name="transform-string">
        <xsl:param name="content"/><xsl:value-of select="translate(translate(normalize-space($content),' &#x9;&#xa;&#xd;', ' '), '&quot;', $APOS)"/>
    </xsl:template>

    <!--  replace-all string maniuplation template
    Parameters:
    + text    - the string to modify
    + replace - the string to replace
    + with    - the string to replace with
    -->
    <xsl:template name="replace-all">
        <xsl:param name="text"/>
        <xsl:param name="replace"/>
        <xsl:param name="with"/>
        <xsl:variable name="textTransformed"><xsl:call-template name="transform-string"><xsl:with-param name="content" select="$text"/></xsl:call-template></xsl:variable>
        <xsl:choose>
            <xsl:when test="contains($textTransformed,$replace)">
                <xsl:value-of select="substring-before($textTransformed,$replace)"/>
                <xsl:value-of select="$with"/>
                <xsl:call-template name="replace-all">
                    <xsl:with-param name="text"
                                    select="substring-after($textTransformed,$replace)"/>
                    <xsl:with-param name="replace" select="$replace"/>
                    <xsl:with-param name="with" select="$with"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$textTransformed"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
